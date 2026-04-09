use reqwest::blocking::Client;
use std::io::{Read, Result, Seek, SeekFrom};

pub struct HttpFile {
    client: Client,
    url: String,
    pos: u64,
    len: u64,
    buffer: Vec<u8>,
    buffer_start: u64,
    buffer_end: u64,
    chunk_size: u64,
}

impl HttpFile {
    pub fn new(url: &str) -> Option<Self> {
        let client = Client::new();
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
            buffer: Vec::new(),
            buffer_start: 0,
            buffer_end: 0,
            chunk_size: 1024 * 512,
        })
    }

    fn fetch_chunk(&mut self, start: u64) -> Result<()> {
        let end = (start + self.chunk_size - 1).min(self.len - 1);
        let range = format!("bytes={}-{}", start, end);
        let mut resp = self
            .client
            .get(&self.url)
            .header(reqwest::header::RANGE, range)
            .send()
            .map_err(|_| std::io::ErrorKind::Other)?;

        self.buffer.clear();
        resp.read_to_end(&mut self.buffer)
            .map_err(|_| std::io::ErrorKind::Other)?;
        self.buffer_start = start;
        self.buffer_end = start + self.buffer.len() as u64;
        Ok(())
    }
}

impl Read for HttpFile {
    fn read(&mut self, buf: &mut [u8]) -> Result<usize> {
        if self.pos >= self.len {
            return Ok(0);
        }

        if self.pos < self.buffer_start || self.pos >= self.buffer_end {
            self.fetch_chunk(self.pos)?;
        }

        let buf_offset = (self.pos - self.buffer_start) as usize;
        let n = std::cmp::min(buf.len(), self.buffer.len() - buf_offset);
        buf[..n].copy_from_slice(&self.buffer[buf_offset..buf_offset + n]);
        self.pos += n as u64;
        Ok(n)
    }
}
impl Seek for HttpFile {
    fn seek(&mut self, pos: SeekFrom) -> Result<u64> {
        self.pos = match pos {
            SeekFrom::Start(p) => p,
            SeekFrom::End(p) => (self.len as i64 + p) as u64,
            SeekFrom::Current(p) => (self.pos as i64 + p) as u64,
        };
        Ok(self.pos)
    }
}
