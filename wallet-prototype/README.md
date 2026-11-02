# NUUR Wallet prototype

An interactive, responsive browser prototype for the NUUR Wallet concept. It is intentionally separate from the Nuur Coin smart-contract implementation.

## Open it

Open `index.html` in a modern browser. No package install, account, API key, or wallet extension is required. The prototype is plain HTML, CSS, and JavaScript.

## Included flows

- Welcome, account creation, security, account-safety guidance, confirmation, and safe account-recovery walkthrough.
- Responsive dashboard with simulated portfolio, asset details, allocation view, and balance visibility control.
- Send flow with asset selection, local public-address and amount validation, transaction preview, and simulated result.
- Receive flow with selectable test asset/network, illustrative QR code, copy, and share interactions.
- Activity history with sent/received/pending filters and simulated transaction detail views.
- Profile, security toggles, preferences, network selection, and connected-apps settings.

## Prototype boundaries

- All balances, prices, addresses, QR output, and transaction records are illustrative demo data.
- No custody provider, signing keys, recovery secrets, or identity-verification workflow is connected.
- Send never signs or broadcasts a transaction. A confirmed send only adds a local simulated activity item.
- Network options are test networks only. No RPC, wallet library, backend, analytics, or real-money service is connected.
- Prototype UI state is held in memory and resets when the page is reloaded.

## Design and responsive notes

The interface uses the midnight navy and gold system, rounded cards, clear testnet labels, and responsive layouts for narrow mobile, tablet, and desktop widths. Mobile uses a compact bottom navigation; wider screens use a left sidebar. The font stack prefers Inter and falls back to system sans-serif. The prototype does not fetch remote fonts or scripts.

## Suggested next design artifacts

Figma system tokens: midnight navy `#101827`, secondary navy `#1D2A3A`, gold `#EFCB64`, emerald `#20C997`, white `#FFFFFF`, secondary text `#AEBACB`, error `#F06464`. Core components include sidebar and mobile navigation, network badge/select, balance card, asset row, activity row, status chip, primary and secondary buttons, form fields, confirmation panel, and empty state.

Core flow map:

```text
Welcome ──┬── Create account ─ Security ─ Account-safety guidance ─ Confirmation ─ Home
          ├── Account-recovery walkthrough ─────────────────────────────────────── Home
          └── Explore demo ─────────────────────────────────────── Home
Home ─ Send ─ Asset ─ Recipient ─ Amount ─ Review ─ Simulated result
Home ─ Receive ─ Asset + test network ─ Address + QR ─ Copy / Share
Home ─ Activity ─ Filter ─ Transaction details
Home ─ Assets ─ Asset details / Portfolio / Network
Home ─ Profile ─ Security / Preferences / Connected apps
```
