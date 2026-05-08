use reqwest::blocking::Client;
use reqwest::header::{HeaderMap, RANGE};
use std::collections::BTreeMap;
use std::io::{Error, ErrorKind, Read, Result, Seek, SeekFrom};

pub struct HttpFile {
    client: Client,
    url: String,
    pos: u64,
    len: u64,

    headers: HeaderMap,

    chunks: BTreeMap<u64, Vec<u8>>,
    chunk_size: u64,

    full_data: Option<Vec<u8>>,
}

impl HttpFile {
    pub fn new(url: &str, chunk_size_kb: u64, headers: HeaderMap) -> Option<Self> {
        let client = Client::new();

        let resp = client
            .get(url)
            .headers(headers.clone())
            .header(RANGE, "bytes=0-0")
            .send()
            .ok();

        let (range_supported, mut len) = if let Some(resp) = resp {
            let supported = resp.status() == reqwest::StatusCode::PARTIAL_CONTENT;

            let size = if supported {
                resp.headers()
                    .get(reqwest::header::CONTENT_RANGE)
                    .and_then(|v| v.to_str().ok())
                    .and_then(|v| v.split('/').nth(1))
                    .and_then(|s| s.parse::<u64>().ok())
                    .unwrap_or(0)
            } else {
                0
            };

            (supported, size)
        } else {
            (false, 0)
        };

        let full_data = if !range_supported {
            let mut resp = client.get(url).headers(headers.clone()).send().ok()?;

            let mut data = Vec::new();
            std::io::copy(&mut resp, &mut data).ok()?;

            len = data.len() as u64;
            Some(data)
        } else {
            None
        };

        Some(Self {
            client,
            url: url.to_string(),
            pos: 0,
            len,
            headers,
            chunks: BTreeMap::new(),
            chunk_size: chunk_size_kb * 1024,
            full_data,
        })
    }

    fn ensure_chunk(&mut self, position: u64) -> Result<&Vec<u8>> {
        let chunk_start = (position / self.chunk_size) * self.chunk_size;

        if !self.chunks.contains_key(&chunk_start) {
            let end = (chunk_start + self.chunk_size - 1).min(self.len.saturating_sub(1));

            let range = format!("bytes={}-{}", chunk_start, end);

            let mut resp = self
                .client
                .get(&self.url)
                .headers(self.headers.clone())
                .header(RANGE, range)
                .send()
                .map_err(|e| Error::new(ErrorKind::Other, e))?;

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

        if let Some(ref data) = self.full_data {
            let available = data.len().saturating_sub(self.pos as usize);
            if available == 0 {
                return Ok(0);
            }

            let n = buf.len().min(available);

            buf[..n].copy_from_slice(&data[self.pos as usize..self.pos as usize + n]);

            self.pos += n as u64;
            return Ok(n);
        }

        let current_pos = self.pos;
        let chunk_size = self.chunk_size;

        let chunk = self.ensure_chunk(current_pos)?;

        let offset = (current_pos % chunk_size) as usize;
        let available = chunk.len().saturating_sub(offset);

        if available == 0 {
            return Ok(0);
        }

        let n = buf.len().min(available);

        buf[..n].copy_from_slice(&chunk[offset..offset + n]);

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
            return Err(Error::new(ErrorKind::InvalidInput, "negative seek"));
        }

        self.pos = new_pos as u64;
        Ok(self.pos)
    }
}
