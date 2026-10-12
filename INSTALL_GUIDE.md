# GhostVault - Installation & Troubleshooting Guide / Kurulum ve Sorun Giderme Kılavuzu


---

## 🛡️ Güvenlik Uyarıları & Kurulum Sorun Giderme (Security & False Positives Guide)

GhostVault, **%100 açık kaynak kodlu** ve şeffaf bir projedir. Tüm kaynak kodları bu depoda denetlenebilir durumdadır. Ancak indirme sırasında işletim sistemleri tarafından aşağıdaki uyarılar verilebilir:

### 🪟 Windows: SmartScreen & Antivirüs Bildirimleri (False Positive)
- **Neden Çıkar?**
  1. **İmzasız Yazılım (Unsigned Binary):** Açık kaynaklı bir proje olduğu ve binlerce liralık yıllık kurumsal kod imzalama sertifikası (EV Code Signing) satın alınmadığı için Microsoft SmartScreen henüz tanınmayan dosyaları "bilinmeyen yayımcı" olarak işaretler.
  2. **Sezgisel Algılama (Heuristics):** GhostVault'un yerel HTTP sunucusu açması ve dahili tünel motoru barındırması, bazı antivirüs yazılımlarının sezgisel motorlarında yanlış alarm (False Positive) üretebilir.
- **Nasıl Çözülür?**
  - **"Windows kişisel bilgisayarınızı korudu" (SmartScreen):**
    1. Ekrana gelen mavi kutuda **"Ek bilgi" (More info)** bağlantısına tıklayın.
    2. Sağ alttaki **"Yine de çalıştır" (Run anyway)** butonuna tıklayın.
  - **Tarayıcı Uyarısı (Chrome / Edge "Zararlı olabilir"):**
    - İndirilenler listesinde dosyanın yanındaki `...` menüsünden **"Sakla" (Keep)** -> **"Yine de sakla"** seçeneğini seçin.

---

### 🍎 macOS: Gatekeeper & "Uygulama Doğrulanamıyor" Bildirimleri
- **Neden Çıkar?**
  - Apple Gatekeeper, Apple Developer kimliğiyle ($99/yıl) noter tasdiki (Notarization) yapılmamış tüm üçüncü taraf açık kaynak uygulamaları varsayılan olarak engeller.
- **Nasıl Çözülür?**
  - **Yöntem 1 (Sağ Tık ile Aç - En Kolay):**
    1. Uygulama simgesine çift tıklamak yerine **Sağ Tıklayın (Control + Tıklama)**.
    2. Açılan menüden **"Aç" (Open)** seçeneğine basın ve onay penceresinde tekrar **"Aç"** deyin.
  - **Yöntem 2 (Sistem Ayarları):**
    1. **Sistem Ayarları** -> **Gizlilik ve Güvenlik** menüsüne gidin.
    2. Sayfanın altındaki Güvenlik bölümünde *"GhostVault engellendi"* uyarısının yanındaki **"Yine de Aç" (Open Anyway)** butonuna tıklayın.
  - **Yöntem 3 ("Hasar görmüş / Çöp sepetine taşıyın" uyarısı için Terminal):**
    ```bash
    sudo xattr -rd com.apple.quarantine /Applications/GhostVault.app
    ```

---

### 🌐 English: Security Warning & Installation FAQ

#### Windows SmartScreen Prompt ("Windows protected your PC"):
1. Click **"More info"**.
2. Click **"Run anyway"**.
*Why:* GhostVault is free and open-source. It does not carry a $500/yr enterprise EV code-signing certificate, causing Windows SmartScreen to flag it until reputation is built.

#### macOS Gatekeeper Prompt ("Cannot be opened because developer cannot be verified"):
1. **Right-click** (or Control-click) `GhostVault.app` -> Select **"Open"** -> Click **"Open"** again.
2. Alternatively, navigate to **System Settings** -> **Privacy & Security** -> Click **"Open Anyway"**.
3. If macOS says the app is damaged due to quarantine attributes, execute:
   ```bash
   sudo xattr -rd com.apple.quarantine /Applications/GhostVault.app
   ```

---

### 🔏 Dosya Bütünlük Doğrulaması (SHA-256 Verification)
GhostVault v1.1.0 `GhostVault_Setup.exe` resmi SHA-256 değeri:
```text
e0e989b9c627bb353e2748c952ff31d08189f5f5cc208161b535036b1c682882
```
Dosyanın değiştirilmediğinden ve orijinal derlemeden geldiğinden emin olmak için:
```powershell
Get-FileHash -Algorithm SHA256 .\GhostVault_Setup.exe
```
