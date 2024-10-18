import Foundation

enum URandomError: Swift.Error {
    case open(Int32)
    case read(Int32)
}

final class URandom {
    private let file: UnsafeMutablePointer<FILE>
    private let path = "/dev/urandom"

    init() throws {
        guard let file = fopen(path, "rb") else {
            // The Random protocol doesn't allow init to fail, so we have to
            // check whether /dev/urandom was successfully opened here
            throw URandomError.open(errno)
        }
        self.file = file
    }

    deinit {
        fclose(file)
    }

    private func read(numBytes: Int) throws -> [UInt8] {
        // Initialize an empty array with space for numBytes bytes
        var bytes = [UInt8](repeating: 0, count: numBytes)
        guard fread(&bytes, 1, numBytes, file) == numBytes else {
            // If the requested number of random bytes couldn't be read,
            // we need to throw an error
            throw URandomError.read(errno)
        }

        return bytes
    }

    /// Get a random array of Bytes
    func bytes(count: Int) throws -> [UInt8] {
        return try read(numBytes: count)
    }
}
