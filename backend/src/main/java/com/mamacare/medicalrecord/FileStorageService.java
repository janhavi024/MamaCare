package com.mamacare.medicalrecord;

import com.mamacare.exception.BadRequestException;
import com.mamacare.exception.ResourceNotFoundException;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Locale;
import java.util.UUID;

/**
 * Stores uploads in a private directory outside any web root under random names. Files are only ever returned
 * through an authenticated, access-checked controller endpoint.
 * NOTE: local-disk storage and no antivirus scanning or encryption at rest; see docs for production guidance.
 */
@Service
public class FileStorageService {
    private static final long MAX_BYTES = 10L * 1024 * 1024;

    private final Path root;

    public FileStorageService(@Value("${app.storage.dir}") String dir) {
        this.root = Paths.get(dir).toAbsolutePath().normalize();
    }

    @PostConstruct
    void init() throws IOException {
        Files.createDirectories(root);
    }

    public record Stored(String key, String originalName, String contentType, long size) {}

    public Stored store(MultipartFile file) {
        if (file == null || file.isEmpty()) throw new BadRequestException("No file received");
        if (file.getSize() > MAX_BYTES) throw new BadRequestException("File is too large (max 10 MB)");
        String original = sanitizeName(file.getOriginalFilename());
        String ext = original.contains(".") ? original.substring(original.lastIndexOf('.') + 1).toLowerCase(Locale.ROOT) : "";
        String type = switch (ext) {
            case "pdf" -> "application/pdf";
            case "png" -> "image/png";
            case "jpg", "jpeg" -> "image/jpeg";
            default -> throw new BadRequestException("Only PDF, PNG and JPEG files are allowed");
        };
        try (InputStream in = file.getInputStream()) {
            byte[] head = in.readNBytes(8);
            if (!matchesMagic(type, head)) throw new BadRequestException("File content does not match its type");
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        String key = UUID.randomUUID() + "." + ext;
        Path target = resolve(key);
        try (InputStream in = file.getInputStream()) {
            Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        return new Stored(key, original, type, file.getSize());
    }

    public Resource load(String key) {
        Path p = resolve(key);
        if (!Files.exists(p)) throw new ResourceNotFoundException("File not found");
        return new FileSystemResource(p);
    }

    public void delete(String key) {
        if (key == null) return;
        try {
            Files.deleteIfExists(resolve(key));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    /** Resolves a storage key and refuses anything that escapes the storage root. */
    private Path resolve(String key) {
        Path p = root.resolve(key).normalize();
        if (!p.startsWith(root)) throw new BadRequestException("Invalid file reference");
        return p;
    }

    private static boolean matchesMagic(String type, byte[] h) {
        if (h.length < 4) return false;
        return switch (type) {
            case "application/pdf" -> h[0] == '%' && h[1] == 'P' && h[2] == 'D' && h[3] == 'F';
            case "image/png" -> (h[0] & 0xFF) == 0x89 && h[1] == 'P' && h[2] == 'N' && h[3] == 'G';
            case "image/jpeg" -> (h[0] & 0xFF) == 0xFF && (h[1] & 0xFF) == 0xD8 && (h[2] & 0xFF) == 0xFF;
            default -> false;
        };
    }

    private static String sanitizeName(String name) {
        String n = name == null ? "file" : name;
        n = n.replace("\\", "/");
        n = n.substring(n.lastIndexOf('/') + 1).replaceAll("[^A-Za-z0-9._ -]", "_").trim();
        if (n.isEmpty()) n = "file";
        return n.length() > 120 ? n.substring(n.length() - 120) : n;
    }
}
