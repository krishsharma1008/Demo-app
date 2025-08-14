/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

/**
 * Enum representing the status of a file download operation (marked @objc for Objective-C interoperability)
 */
@objc public enum FileDownloadStatus: Int32, CaseIterable {
    case DOWNLOAD_UNKNOWN = 0
    case DOWNLOAD_RUNNING = 1
    case DOWNLOAD_SUCCESS = 2
    case DOWNLOAD_FAILURE = 3
    case DOWNLOAD_PENDING = 4
}

/**
 * Class containing information about a file download operation (changed from struct to support @objc interoperability)
 */
@objc public class FileDownloadInfo: NSObject {
    public let status: FileDownloadStatus
    public let fileName: String
    public let url: String
    public let filePath: String
    public let downloadedBytes: Int64
    public let totalBytes: Int64
    public let errorMessage: String?
    public let timeElapsed: Int32

    @objc public init(status: FileDownloadStatus = .DOWNLOAD_UNKNOWN,
                fileName: String = "",
                url: String = "",
                filePath: String = "",
                downloadedBytes: Int64 = 0,
                totalBytes: Int64 = 0,
                errorMessage: String? = nil,
                timeElapsed: Int32 = -1) {
        self.status = status
        self.fileName = fileName
        self.url = url
        self.filePath = filePath
        self.downloadedBytes = downloadedBytes
        self.totalBytes = totalBytes
        self.errorMessage = errorMessage
        self.timeElapsed = timeElapsed
    }
}

/**
 * Class representing a network response from C++ interop (changed from struct to support @objc interoperability)
 */
@objc public class CNetworkResponse: NSObject {
    public let statusCode: Int32
    public let headers: String
    public let body: UnsafePointer<CChar>?
    public let bodyLength: Int32

    @objc public init(statusCode: Int32 = 0,
                headers: String = "",
                body: UnsafePointer<CChar>? = nil,
                bodyLength: Int32 = 0) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.bodyLength = bodyLength
    }
}

// Convenience constants for backward compatibility
public let DOWNLOAD_UNKNOWN = FileDownloadStatus.DOWNLOAD_UNKNOWN
public let DOWNLOAD_RUNNING = FileDownloadStatus.DOWNLOAD_RUNNING
public let DOWNLOAD_SUCCESS = FileDownloadStatus.DOWNLOAD_SUCCESS
public let DOWNLOAD_FAILURE = FileDownloadStatus.DOWNLOAD_FAILURE
public let DOWNLOAD_PENDING = FileDownloadStatus.DOWNLOAD_PENDING
