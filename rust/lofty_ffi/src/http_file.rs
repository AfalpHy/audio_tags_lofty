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
}

impl HttpFile {
    /// Creates a new HttpFile instance.
    /// @param url: The target WebDAV/HTTP URL.
    /// @param chunk_size_kb: Desired chunk size in Kilobytes (e.g., 128, 512).
    pub fn new(url: &str, chunk_size_kb: u64) -> Option<Self> {
        let client = Client::new();

        // Fetch metadata to get Content-Length
        let resp = client.head(url).send().ok()?;
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
            // Convert KB to Bytes
            chunk_size: chunk_size_kb * 1024,
        })
    }

    /// Retrieves a chunk from memory or fetches it from the server if missing.
    fn get_or_fetch_chunk(&mut self, position: u64) -> Result<&Vec<u8>> {
        // Calculate the aligned starting boundary of the chunk
        let chunk_start = (position / self.chunk_size) * self.chunk_size;

        if !self.chunks.contains_key(&chunk_start) {
            let end = (chunk_start + self.chunk_size - 1).min(self.len - 1);
            let range = format!("bytes={}-{}", chunk_start, end);

            let mut resp = self
                .client
                .get(&self.url)
                .header(reqwest::header::RANGE, range)
                .send()
                .map_err(|e| Error::new(ErrorKind::Other, e))?;

            let mut data = Vec::new();
            resp.read_to_end(&mut data)
                .map_err(|e| Error::new(ErrorKind::Other, e))?;

            self.chunks.insert(chunk_start, data);
        }

        // Unwrapping is safe because we just inserted it if it was missing
        Ok(self.chunks.get(&chunk_start).unwrap())
    }
}

impl Read for HttpFile {
    fn read(&mut self, buf: &mut [u8]) -> Result<usize> {
        // Handle EOF (End Of File)
        if self.pos >= self.len {
            return Ok(0);
        }

        let current_pos = self.pos;
        let c_size = self.chunk_size;

        // 1. Get the data chunk containing the current position
        let chunk_data = self.get_or_fetch_chunk(current_pos)?;

        // 2. Calculate the offset relative to the start of this specific chunk
        let offset_in_chunk = (current_pos % c_size) as usize;

        // 3. Determine how many bytes we can actually read
        // It's the minimum of: target buffer size vs remaining bytes in chunk
        let available_in_chunk = chunk_data.len().saturating_sub(offset_in_chunk);
        if available_in_chunk == 0 {
            return Ok(0);
        }

        let n = std::cmp::min(buf.len(), available_in_chunk);

        // 4. Copy data from internal cache to the provided buffer
        buf[..n].copy_from_slice(&chunk_data[offset_in_chunk..offset_in_chunk + n]);

        // 5. Advance the internal file pointer
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
            return Err(Error::new(
                ErrorKind::InvalidInput,
                "Cannot seek to a negative position",
            ));
        }

        self.pos = new_pos as u64;
        Ok(self.pos)
    }
}
