//
//  LegacySettingsHorizontalTopBar.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct LegacySettingsHorizontalTopBar: View {
    
    @Environment(\.openURL) var openURL
    
    @State private var checkingUpdate = false
    @State private var updateAvailable = false
    @State private var latestVersion: String = ""
    @State private var releaseURL: URL? = nil
    
    @AS(Key.hideUpdate) private var hideUpdate = false

    private var updateFeedConfigured: Bool {
        Utils.Miscellaneous.latestRepoGithubApi != nil
    }
    
    private var updateButtonLabel: String {
        
        if updateAvailable {
            return "\("download".localized) (v\(latestVersion))";
        }
        
        if checkingUpdate {
            return "looking_for_updates"
        } else if latestVersion.isEmpty {
            return "check_for_updates"
        } else {
            return "updated"
        }
    }
    
    private func updateButtonAction() {
        
        if updateAvailable, let releaseURL {
            openURL(releaseURL)
            return
        }
        
        checkingUpdate = true
        updateAvailable = false
        latestVersion = ""
        releaseURL = nil
        
        guard
            let feedURL = Utils.Miscellaneous.latestRepoGithubApi,
            let url = URL(string: feedURL)
        else {
            checkingUpdate = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            defer { checkingUpdate = false }
            guard let data = data, error == nil else { return }
            
            if let release = try? JSONDecoder().decode(GitHubRelease.self, from: data) {
                let latest = release.tag_name.replacingOccurrences(of: "v", with: "")
                latestVersion = latest
                releaseURL = URL(string: release.html_url)
                
                DispatchQueue.main.async {
                    updateAvailable = Utils.App.isVersion(Utils.App.appVersion, olderThan: latest)
                }
            }
        }.resume()
    }
    
    var body: some View {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("MenuBarUSB-TB")
                    .font(.title2)
                    .bold()
                Text(
                    String(
                        format: NSLocalizedString("version", comment: "APP VERSION"),
                        "\(Utils.App.appVersion) - OS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
                    )
                )
                .font(.footnote)
                .foregroundColor(.secondary)
            }
            Spacer()

            if updateAvailable, let releaseURL {
                HStack(alignment: .center, spacing: 6) {
                    Button(action: {
                        updateAvailable = false
                        latestVersion = ""
                    }) {
                        Image(systemName: "x.circle")
                    }

                    Link(
                        "\("open_download_page".localized) (v\(latestVersion))",
                        destination: releaseURL
                    )
                    .buttonStyle(.borderedProminent)
                }
            }

            if !updateAvailable {
                HStack {
                    if !hideUpdate && updateFeedConfigured {
                        Button(updateButtonLabel.localized) {
                            updateButtonAction()
                        }
                        .foregroundStyle(updateAvailable ? AssetColors.update : .primary)
                    }
                    
                }
            }
        }
    }
}
