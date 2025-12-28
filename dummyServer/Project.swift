import ProjectDescription

let project = Project(
    name: "dummyServer",
    targets: [
        .target(
            name: "dummyServer",
            destinations: .macOS,
            product: .app,
            bundleId: "com.Nine99.dummyServer",
            infoPlist: .extendingDefault(
                with: [:]
            ),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "A7YCA4UNT9",
                ],
                configurations: [],
                defaultSettings: .recommended
            )
        ),
    ]
)

