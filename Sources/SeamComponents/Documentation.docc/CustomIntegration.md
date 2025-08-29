# Custom Integration with SeamComponents

SeamComponents is designed for flexibility—so you can use as much or as little as you need. This guide explains how to build your own user experience with the building blocks SeamComponents provides.

---

While the all-in-one ``SeamAccessView`` is the fastest way to integrate mobile keys, many apps need more customization. SeamComponents supports dependency injection, allowing you to:

- Use key list, credential card, unlock button, and error banner views directly
- Provide your own data sources, event handlers, and state logic
- Inject a live `SeamService` or a mock conforming to `SeamServiceProtocol` for previews and tests

The `SeamService` exposes published state (`credentials`, `isActive`) and Combine publishers (`credentialsPublisher`, `isActivePublisher`).

---

## Building Blocks

SeamComponents exports a variety of reusable, domain-specific SwiftUI views. Here are the main building blocks:

- **``SeamAccessView``**  
  All-in-one mobile access experience; handles login, credential fetching, unlocking, and error display.

- **``SeamCredentialsView``**  
  Coordinator/container view that manages sheet presentation, selection, refreshing (pull-to-refresh), and empty state handling using `SeamNoCredentialsView`. It renders the reusable, pure ``SeamCredentialGrid`` or ``SeamCredentialTable`` subview for displaying credentials. Unlocking logic, as well as any credential-specific error handling or feedback, is delegated to the unlock view (e.g., ``SeamUnlockCardView``), which is presented as a sheet when a credential is selected.  
  You can provide a custom ``SeamAccessCredentialErrorStyle`` to control how errors and statuses are displayed on each key card. Credentials are kept up to date automatically by the service; pull‑to‑refresh simply triggers an immediate `refresh()` call.

- **``SeamCredentialGrid``**  
  Pure, stateless subview for displaying credentials in a grid layout. Can be composed in custom layouts or used independently.

- **``SeamCredentialTable``**  
  Pure, stateless subview for displaying credentials in a list/table format. Can be composed in custom layouts or used independently.

- **``SeamKeyCardView``**  
  Shows an individual credential as a visually rich "key card," including credential details, status, and errors.  
  Status and error overlays can be fully customized using ``SeamAccessCredentialErrorStyle``.

- **``SeamUnlockCardView``**  
  Manages all unlock functionality for a selected credential, including progress and error feedback.  
  Status and error overlays can be fully customized using ``SeamAccessCredentialErrorStyle``.

Each component is designed to work with a single service wrapper conforming to `SeamServiceProtocol` (backed by the live `SeamService` in production), so you can inject live or mock implementations as needed.

---

## Example: Custom Key List and Unlock Flow

You can create and own a ``SeamCredentialsViewModel``, passing it to the credential views. Credential selection can be handled using the `selectedCredentialId` property and the `select(credential:)` method on the view model.

You can use the coordinator views (``SeamCredentialsView``) for an all-in-one solution that handles selection, navigation, refreshing, and empty state UI automatically. These views also manage sheet presentation for unlocking credentials and delegate unlocking logic and any credential-specific error handling or feedback to the unlock view presented as a sheet.

Alternatively, if you want full control over selection and navigation, you can compose with the pure, stateless ``SeamCredentialGrid`` or ``SeamCredentialTable`` subviews directly. When doing so, call your service’s `unlock(using:timeout:)` and subscribe to the returned `AnyPublisher<SeamAccessUnlockEvent, Never>` to track progress and outcomes. In this case, you will need to handle empty states, unlock sheet presentation, and unlocking/error logic yourself.

```swift
import SeamComponents

struct CustomKeysScreen: View {
    @StateObject var viewModel = SeamCredentialsViewModel(seam: SeamService())

    var body: some View {
        VStack {
            // Use the coordinator/container view for grid layout with built-in selection, refresh handling,
            // empty state UI, and unlock sheet presentation.
            SeamCredentialsGridView(viewModel: viewModel)
            // Or, use the coordinator/container view for table layout:
            // SeamCredentialsTableView(viewModel: viewModel)

            // If you want to handle selection/navigation yourself, compose with the pure subviews:
            // SeamCredentialGrid(credentials: viewModel.credentials, selectedId: viewModel.selectedCredentialId, onSelect: viewModel.select)
            // SeamCredentialTable(credentials: viewModel.credentials, selectedId: viewModel.selectedCredentialId, onSelect: viewModel.select)

            // When using pure subviews, you'll need to manage empty states and unlock sheet presentation yourself.
            // Unlocking and credential error handling are managed by the unlock view when presented.
            // You can customize how credential errors/statuses appear by passing your own `SeamAccessCredentialErrorStyle` to these views.
            if let selectedId = viewModel.selectedCredentialId {
                SeamUnlockCardView(
                    viewModel: SeamUnlockCardViewModel(
                        credentialId: selectedId,
                        service: viewModel.service
                    )
                )
            }
        }
    }
}
```

**In Previews or Tests:**
```swift
#Preview {
    CustomKeysScreen()
}
```

> **Tip:** Use the coordinator views for a full-featured experience—empty states, selection, refresh, and unlock presentation are all handled for you.

---

## Dependency Injection & Mocks

SeamComponents now uses a single **wrapper ObservableObject** API for integration:

- **Protocol:** ``SeamServiceProtocol`` — what your UI / view models depend on
- **Production implementation:** ``SeamService`` — mirrors `Seam` state and forwards commands
- **Test/Preview doubles:** conforming classes (e.g., `MockSeamService`) that you fully control

### Live usage
```swift
let service: SeamServiceProtocol = SeamService()
let vm = SeamCredentialsViewModel(seam: service)
```

### Mock usage (tests / previews)
```swift
final class MockSeamService: SeamServiceProtocol {
    @Published private(set) var credentials: [SeamAccessCredential] = []
    @Published private(set) var isActive: Bool = false
    
    // Protocol publishers
    var isActivePublisher: AnyPublisher<Bool, Never> { $isActive.eraseToAnyPublisher() }
    var credentialsPublisher: AnyPublisher<[SeamAccessCredential], Never> { $credentials.eraseToAnyPublisher() }
    
    // Commands you control in tests
    func initialize(clientSessionToken: String?) throws {}
    func activate() async throws { isActive = true }
    @discardableResult
    func refresh() async throws -> [SeamAccessCredential] { credentials }
    // Emits SeamAccessUnlockEvent values and never fails.
    func unlock(using credentialId: String, timeout: TimeInterval) throws -> AnyPublisher<SeamAccessUnlockEvent, Never> {
        Just(.launched).append(Just(.grantedAccess)).eraseToAnyPublisher()
    }
    func deactivate(deintegrate: Bool) async { isActive = false }
}

// Inject into your VM
let mock = MockSeamService()
let vm = SeamCredentialsViewModel(seam: mock)
```

This design keeps your UI and business logic independent of concrete SDK types or singletons while remaining iOS 16–friendly.

---

## Custom Styling and Extensibility

All views are built with SwiftUI best practices—using system fonts, SFSymbols, and color styles. You can:

- Override styles using environment modifiers
- Add your own accessibility and localization
- Compose SeamComponents with your own views and navigation
- Use ``SeamAccessCredentialErrorStyle`` to override error/status badge appearance, icons, and messaging in key card and unlock views.

### Theming and Appearance

SeamComponents provides a powerful theming system using the ``SeamTheme`` type. You can inject a custom theme into the SwiftUI environment, which will be respected by all SeamComponents in your view hierarchy. This enables full white-labeling and consistent branding across your app.

The theming API uses a builder pattern with nested `.with` methods, allowing you to override specific parts of the theme selectively. For example, you can customize the key card appearance by overriding its background gradient, accent color, and corner radius:

```swift
import SeamComponents

let customTheme = SeamTheme.default.with(
    keyCard: .default.with(
        backgroundGradient: [Color.white, Color.blue],
        accentColor: .blue,
        cornerRadius: 16
    )
)
```

Or, you can override colors and fonts globally with partial overrides:

```swift
let brandedTheme = SeamTheme.default.with(
    colors: .default.with(accent: .purple),
    fonts: .default.with(title: .system(size: 26, weight: .bold, design: .rounded))
)
```

These nested `.with` methods allow you to create partial overrides without needing to redefine the entire theme. Unspecified properties fall back to the default values, making it easy to maintain consistent styling while customizing only what you need.

All SeamComponents—including credential lists, key cards, and unlock views—automatically use the current theme from the environment. This means you can white-label your app or support multiple brands with minimal effort.

---

## Advanced: Handling Events and Errors

SeamComponents surfaces events (such as unlock progress or credential errors) via Combine publishers. The unlock stream emits ``SeamAccessUnlockEvent`` values and never fails. The available unlock events are:

- `launched` – the unlock process started (scanning/probing).
- `grantedAccess` – access granted by the lock (success).
- `timedOut` – the attempt timed out without success.
- `connectionFailed(debugDescription:)` – connection or protocol negotiation failed.

You can:

- Subscribe to these events to show custom notifications
- Present modals or banners for user actions
- Log analytics or trigger side effects

Refer to individual component documentation for details.

### Credential Errors & Presentation

Seam surfaces per‑credential issues via each credential’s `errors: [SeamCredentialError]` array and may also prevent unlock by throwing `SeamError.credentialErrors([…])` when preconditions aren’t met. Use ``SeamAccessCredentialErrorStyle`` to present badges, messages, and actions consistently across cards and unlock views.

**Credential error types**

- `awaitingLocalCredential` — Waiting for a local credential to become available.
- `expired` — The credential has expired and can’t be used.
- `userInteractionRequired(action)` — The user must perform a specific action (see actions below).
- `contactSeamSupport` — Configuration error that requires developer attention; guide users to contact support.
- `unsupportedDevice` — The current device isn’t supported for this credential.
- `unknown` — An unclassified or unexpected issue occurred.

**Possible `userInteractionRequired` actions**

- `completeOtpAuthorization(otpUrl:)` — Open the provided URL to complete OTP authorization.
- `enableInternet` — Prompt the user to enable internet connectivity.
- `enableBluetooth` — Prompt the user to turn on Bluetooth.
- `grantBluetoothPermission` — Direct the user to grant Bluetooth permission.
- `appRestartRequired` — Ask the user to restart the app.

**Presentation tips**

- The `errors` array is ordered by severity/priority. Show the first item as the primary badge on a key card, and reveal details or actions on tap.
- You can fully customize copy, icons, and actions by providing your own ``SeamAccessCredentialErrorStyle`` to grid/table/key‑card/unlock views.

**Example: Rendering error UI on a key card**

```swift
let style = SeamAccessCredentialErrorStyle.default
let theme = SeamTheme.default

SeamKeyCardView(credential: credential, style: style)
    .overlay(alignment: .bottomLeading) {
        if let error = credential.errors.first {
            HStack(spacing: 8) {
                Image(systemName: style.systemIcon(error, theme: theme))
                Text(style.message(error))
            }
            .padding(8)
        }
    }
```

**Example: Offering a corrective action**

```swift
if let error = credential.errors.first,
   let actionTitle = style.primaryActionTitle(error) {
    Button(actionTitle) {
        style.primaryAction(error)() // e.g., open Settings or OTP URL
    }
}
```

> Tip: If `unlock(using:)` throws `.credentialErrors([…])`, present the top error using your style and avoid starting the unlock until it’s resolved.

---

## Further Reading

- [Seam SDK Documentation](https://docs.seam.co/)
- [Support](https://docs.seam.co/support)
- [Getting Started](doc:GettingStarted)
- [Customizing Appearance](doc:CustomizingAppearance)

---

**With these building blocks, you’re ready to craft a seamless, custom mobile access experience!**
