package com.mamacare.medicalrecord;

import com.mamacare.exception.BadRequestException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

class FileStorageServiceTest {
    @TempDir Path dir;

    private FileStorageService service() throws Exception {
        FileStorageService s = new FileStorageService(dir.toString());
        s.init();
        return s;
    }

    @Test
    void storesValidPdfUnderRandomKeyAndSanitizesName() throws Exception {
        FileStorageService s = service();
        var f = new MockMultipartFile("file", "../../etc/My Report!.pdf", "application/pdf", "%PDF-1.4 test".getBytes(StandardCharsets.UTF_8));
        var stored = s.store(f);
        assertTrue(stored.key().endsWith(".pdf"));
        assertFalse(stored.key().contains("Report"));
        assertFalse(stored.originalName().contains("/"));
        assertTrue(Files.exists(dir.resolve(stored.key())));
        assertNotNull(s.load(stored.key()));
        s.delete(stored.key());
        assertFalse(Files.exists(dir.resolve(stored.key())));
    }

    @Test
    void rejectsWrongExtensionAndMismatchedContent() throws Exception {
        FileStorageService s = service();
        assertThrows(BadRequestException.class, () -> s.store(new MockMultipartFile("file", "run.exe", "application/octet-stream", "MZ....".getBytes())));
        assertThrows(BadRequestException.class, () -> s.store(new MockMultipartFile("file", "fake.pdf", "application/pdf", "not a pdf".getBytes())));
        assertThrows(BadRequestException.class, () -> s.store(new MockMultipartFile("file", "x.png", "image/png", new byte[0])));
    }

    @Test
    void refusesPathTraversalOnLoad() throws Exception {
        FileStorageService s = service();
        assertThrows(BadRequestException.class, () -> s.load("../outside.txt"));
        assertThrows(BadRequestException.class, () -> s.delete("../../outside.txt"));
    }
}
