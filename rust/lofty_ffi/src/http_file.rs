use reqwest::blocking::Client;
use std::collections::BTreeMap;
use std::io::{Error, ErrorKind, Read, Result, Seek, SeekFrom};

pub struct HttpFile {
    client: Client,
    url: String,
    pos: u64,
    len: u64,
    // Storage for downloaded data segments to prevent re-downloading
    chunks: BTreeMap<u64, Vec<u8>>,
    // Size of each network request
    chunk_size: u64,

    // Optional authentication
    username: Option<String>,
    password: Option<String>,
}

impl HttpFile {
    /// Creates a new HttpFile instance.
    /// @param url: Target HTTP/WebDAV URL
    /// @param chunk_size_kb: Chunk size in KB
    /// @param username/password: Optional Basic Auth credentials
    pub fn new(
        url: &str,
        chunk_size_kb: u64,
        username: Option<&str>,
        password: Option<&str>,
    ) -> Option<Self> {
        let client = Client::new();

        let mut req = client.head(url);

        // Apply Basic Auth if provided
        if let (Some(u), Some(p)) = (username, password) {
            req = req.basic_auth(u, Some(p));
        }

        let resp = req.send().ok()?;

        let len = resp
            .headers()
            .get(reqwest::header::CONTENT_LENGTH)?
            .to_str()
            .ok()?
            .parse::<u64>()
            .ok()?;

        Some(Self {
            client,
            url: url.to_string(),
            pos: 0,
            len,
            chunks: BTreeMap::new(),
            chunk_size: chunk_size_kb * 1024,
            username: username.map(|s| s.to_string()),
            password: password.map(|s| s.to_string()),
        })
    }

    /// Fetch a chunk from cache or server
    fn get_or_fetch_chunk(&mut self, position: u64) -> Result<&Vec<u8>> {
        let chunk_start = (position / self.chunk_size) * self.chunk_size;

        if !self.chunks.contains_key(&chunk_start) {
            let end = (chunk_start + self.chunk_size - 1).min(self.len - 1);
            let range = format!("bytes={}-{}", chunk_start, end);

            let mut req = self
                .client
                .get(&self.url)
                .header(reqwest::header::RANGE, range);

            // Apply Basic Auth if provided
            if let (Some(u), Some(p)) = (&self.username, &self.password) {
                req = req.basic_auth(u, Some(p));
            }

            let mut resp = req.send().map_err(|e| Error::new(ErrorKind::Other, e))?;

            let mut data = Vec::new();
            resp.read_to_end(&mut data)
                .map_err(|e| Error::new(ErrorKind::Other, e))?;

            self.chunks.insert(chunk_start, data);
        }

        Ok(self.chunks.get(&chunk_start).unwrap())
    }
}

impl Read for HttpFile {
    fn read(&mut self, buf: &mut [u8]) -> Result<usize> {
        if self.pos >= self.len {
            return Ok(0);
        }

        let current_pos = self.pos;
        let c_size = self.chunk_size;

        let chunk_data = self.get_or_fetch_chunk(current_pos)?;

        let offset_in_chunk = (current_pos % c_size) as usize;

        let available = chunk_data.len().saturating_sub(offset_in_chunk);
        if available == 0 {
            return Ok(0);
        }

        let n = std::cmp::min(buf.len(), available);

        buf[..n].copy_from_slice(&chunk_data[offset_in_chunk..offset_in_chunk + n]);

        self.pos += n as u64;

        Ok(n)
    }
}

impl Seek for HttpFile {
    fn seek(&mut self, pos: SeekFrom) -> Result<u64> {
        let new_pos = match pos {
            SeekFrom::Start(p) => p as i64,
            SeekFrom::End(p) => self.len as i64 + p,
            SeekFrom::Current(p) => self.pos as i64 + p,
        };

        if new_pos < 0 {
            return Err(Error::new(ErrorKind::InvalidInput, "Negative seek"));
        }

        self.pos = new_pos as u64;
        Ok(self.pos)
    }
}
