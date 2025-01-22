//
//  MailZipFileManager.swift
//  Tangem
//
//  Created by Andrey Fedorov on 27.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import MessageUI
import ZIPFoundation

final class MailZipFileManager {
    static let shared = MailZipFileManager()

    private var fileManager: FileManager { .default }
    private var destinationURL: URL { fileManager.temporaryDirectory }

    private init() {}

    func attachZipData(at url: URL, to viewController: MFMailComposeViewController) throws {
        let archiveName = url.appendingPathExtension(for: .zip).lastPathComponent
        let destinationURL = destinationURL.appendingPathComponent(archiveName, conformingTo: .zip)

        try? fileManager.removeItem(at: destinationURL)
        try fileManager.zipItem(at: url, to: destinationURL, shouldKeepParent: false, compressionMethod: .deflate)

        let data = try Data(contentsOf: destinationURL)
        viewController.addAttachmentData(data, mimeType: "application/zip", fileName: archiveName)

        cleanZipData()
    }

    func cleanZipData() {
        do {
            let files = try fileManager.contentsOfDirectory(at: destinationURL, includingPropertiesForKeys: nil)

            for file in files {
                guard file.pathExtension == "zip" else {
                    continue
                }

                do {
                    try fileManager.removeItem(at: file)
                } catch {
                    AppLog.shared.debug("Failed to remove zip file at path '\(file.path)'. Error: \(error)")
                }
            }
        } catch {
            AppLog.shared.debug("Failed to fetch content of the directory at path '\(destinationURL)'. Error: \(error)")
        }
    }
}
