import 'package:flutter/foundation.dart';

import 'services/wallet_storage.dart';

/// Tiny two-locale string table. Every visible label goes through here so the
/// language picked during onboarding (or later in Settings) applies app-wide.
class S {
  static String _locale = 'id';
  static bool _chosen = false;

  /// Bumped on every language change; the app root listens and rebuilds.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static String get locale => _locale;
  static bool get isId => _locale == 'id';

  /// True once the user has picked a language, so onboarding can skip the
  /// picker for returning users.
  static bool get chosen => _chosen;

  /// Preview-only override used by the screenshot harness.
  static void previewChosen(bool v) => _chosen = v;

  /// Loads the saved locale before the first frame. Falls back to Indonesian.
  static Future<void> load() async {
    try {
      final saved = await WalletStorage.loadLocale();
      if (saved == 'id' || saved == 'en') {
        _locale = saved!;
        _chosen = true;
      }
    } catch (_) {
      // Secure storage unavailable (fresh desktop without a keyring):
      // keep the default so the app still starts.
    }
  }

  /// Applies and persists a language choice.
  static Future<void> pick(String l) async {
    setLocale(l);
    _chosen = true;
    try {
      await WalletStorage.saveLocale(l);
    } catch (_) {}
  }

  static void setLocale(String l) {
    if (l != 'id' && l != 'en') return;
    if (_locale == l) return;
    _locale = l;
    revision.value++;
  }

  static String _t(String id, String en) => _locale == 'id' ? id : en;

  // Shared
  static String get appName => 'CEN Wallet';
  static String get nonKustodial =>
      _t('Non-kustodial · Mainnet', 'Non-custodial · Mainnet');
  static String get dompetSub =>
      _t('Dompet digital non-kustodial', 'Non-custodial digital wallet');
  static String get memuat => _t('Memuat…', 'Loading…');
  static String get salin => _t('Salin', 'Copy');
  static String get tutup => _t('Tutup', 'Close');
  static String get batal => _t('Batal', 'Cancel');
  static String get simpan => _t('Simpan', 'Save');
  static String get kembali => _t('Kembali', 'Back');
  static String get kembaliKePilihan =>
      _t('Kembali ke pilihan wallet', 'Back to wallet options');
  static String get lanjut => _t('Lanjutkan', 'Continue');
  static String get ganti => _t('Ganti', 'Change');
  static String get lihat => _t('Lihat', 'View');
  static String get hapus => _t('Hapus', 'Delete');

  // Language step
  static String get pilihBahasa => _t('Pilih bahasa', 'Choose your language');
  static String get pilihBahasaSub => _t(
        'Bahasa berlaku untuk seluruh aplikasi. Bisa diubah kapan saja di Setelan.',
        'Applies to the whole app. You can change it later in Settings.',
      );
  static String get bahasaIndonesia => 'Bahasa Indonesia';
  static String get bahasaInggris => 'English';
  static String get bahasaInduk => _t('Indonesia', 'Indonesian');
  static String get bahasaInggrisInduk => _t('Inggris', 'English');

  // Sidebar
  static String get dompet => _t('Dompet', 'Wallet');
  static String get kirim => _t('Kirim', 'Send');
  static String get terima => _t('Terima', 'Receive');
  static String get riwayat => _t('Riwayat', 'History');
  static String get setelan => _t('Setelan', 'Settings');
  static String get utama => _t('Utama', 'Main');
  static String get lainnya => _t('Lainnya', 'More');
  static String get sinkronMainnet =>
      _t('Sinkron · mainnet', 'Synced · mainnet');

  // Onboarding
  static String get onboardingTagline => _t(
        'Wallet non-kustodial untuk Celenium mainnet.\nKunci privat hanya tersimpan di perangkatmu.',
        'A non-custodial wallet for Celenium mainnet.\nYour private keys never leave this device.',
      );
  static String get buatWalletBaru =>
      _t('Buat wallet baru', 'Create new wallet');
  static String get imporFrasa =>
      _t('Impor dari frasa pemulihan', 'Import from recovery phrase');
  static String get onboardingNote => _t(
        'Dengan melanjutkan, kamu memahami bahwa frasa pemulihan adalah satu-satunya cara memulihkan wallet.',
        'By continuing, you understand that the recovery phrase is the only way to restore this wallet.',
      );
  static String get labelFrasa =>
      _t('Frasa pemulihan 12/24 kata', '12/24-word recovery phrase');
  static String get impor => _t('Impor', 'Import');
  static String get errFrasaJumlah =>
      _t('Frasa harus 12 atau 24 kata', 'Phrase must be 12 or 24 words');
  static String errFrasaKataAsing(String words) => _t(
      'Kata tidak ada di daftar BIP39: $words',
      'Not in the BIP39 wordlist: $words');
  static String get errFrasaChecksum => _t(
      'Kata-kata itu tidak membentuk frasa yang sah. Periksa urutan dan ejaannya.',
      'Those words do not form a valid phrase. Check the order and spelling.');
  static String get errFrasaWordlist => _t(
      'Daftar kata pemulihan belum termuat. Coba lagi sebentar.',
      'The recovery wordlist is still loading. Try again in a moment.');
  static String errBuatWallet(Object e) =>
      _t('Gagal membuat wallet: $e', 'Could not create wallet: $e');
  static String errFrasaTidakValid(Object e) =>
      _t('Frasa tidak valid: $e', 'Invalid phrase: $e');

  // Dompet
  static String get saldoTersedia => _t('Saldo tersedia', 'Available balance');
  static String get aktivitas => _t('Aktivitas', 'Activity');
  static String get alamat => _t('Alamat', 'Address');
  static String get mainnetSinkron =>
      _t('Mainnet · Sinkron', 'Mainnet · Synced');
  static String get pradha => _t('pradha', 'pradha');

  // Kirim
  static String get kirimCEN => _t('Kirim CEN', 'Send CEN');
  static String get saldo => _t('Saldo', 'Balance');
  static String get alamatTujuan => _t('Alamat tujuan', 'Recipient address');
  static String get nominalLabel => _t('Nominal', 'Amount');
  static String get jumlahCEN => _t('Jumlah (CEN)', 'Amount (CEN)');
  static String get biayaJaringan => _t('Biaya jaringan', 'Network fee');
  static String get biayaJaringanPerkiraan =>
      _t('Biaya jaringan (perkiraan)', 'Network fee (estimate)');
  static String get totalDipotong => _t('Total dipotong', 'Total deducted');
  static String get feeFinalOtomatis => _t(
        'Biaya final mengikuti ukuran transaksi saat dikirim.',
        'The final fee follows the transaction size on send.',
      );
  static String get ringkasan => _t('Ringkasan', 'Summary');
  static String get tinjauKirim => _t('Tinjau & Kirim', 'Review & Send');
  static String get kirimDesc => _t(
        'Kirim CEN ke alamat tujuan. Verifikasi PIN atau sidik jari akan diminta sebelum transaksi dikirim.',
        'Send CEN to a recipient. You will confirm with PIN or fingerprint before it goes on-chain.',
      );
  static String get pindaiQR => _t('Pindai QR', 'Scan QR');
  static String get scanAlamatSub => _t('Scan alamat dari QR dompet penerima.',
      'Read the recipient address from a wallet QR.');
  static String get mengirim => _t('Mengirim…', 'Sending…');
  static String get catatanKirim => _t(
        'Transaksi dikonfirmasi dengan sidik jari (jika aktif) atau PIN sebelum dikirim ke jaringan.',
        'Transactions are confirmed with fingerprint (if enabled) or PIN before broadcast.',
      );
  static String get konfirmasiPengiriman =>
      _t('Konfirmasi Pengiriman', 'Confirm transfer');
  static String get konfirmasiSub => _t(
      'Masukkan PIN untuk mengonfirmasi transaksi',
      'Enter your PIN to confirm the transfer');
  static String get alamatWajib =>
      _t('Alamat tujuan wajib diisi', 'Recipient address is required');
  static String get jumlahTidakValid =>
      _t('Jumlah tidak valid', 'Amount is invalid');
  static String get minimalKirim => _t(
      'Minimal kirim 1.000 pradha (0,00001 CEN)',
      'Minimum transfer is 1,000 pradha (0.00001 CEN)');
  static String get verifikasiGagal => _t(
      'Transaksi dibatalkan: verifikasi tidak berhasil',
      'Transfer cancelled: verification failed');
  static String terkirim(String txid) =>
      _t('Terkirim. TXID: $txid', 'Sent. TXID: $txid');
  static String gagal(Object e) => _t('Gagal: $e', 'Failed: $e');
  static String get biometrikKirim => _t(
      'Konfirmasi sidik jari untuk mengirim CEN',
      'Confirm with fingerprint to send CEN');

  // Terima
  static String get terimaCEN => _t('Terima CEN', 'Receive CEN');
  static String get terimaDesc => _t(
        'Tunjukkan QR ini atau bagikan alamatmu untuk menerima CEN.',
        'Show this QR or share your address to receive CEN.',
      );
  static String get alamatDompetAnda =>
      _t('Alamat dompet Anda', 'Your wallet address');
  static String get mainnetAlamatAktif =>
      _t('Mainnet · alamat aktif', 'Mainnet · active address');
  static String get alamatWallet =>
      _t('Alamat wallet-mu (CEN mainnet)', 'Your wallet address (CEN mainnet)');
  static String get salinAlamat => _t('Salin alamat', 'Copy address');
  static String get bagikanQR => _t('Bagikan QR', 'Share QR');
  static String get jaringan => _t('Jaringan', 'Network');
  static String get tipe => _t('Tipe', 'Type');
  static String get alamatDisalin => _t('Alamat disalin', 'Address copied');
  static String get terimaNote => _t(
        'Alamat ini milikmu sepenuhnya dan tidak pernah berubah.',
        'This address is yours and never changes.',
      );

  // Riwayat
  static String get semua => _t('Semua', 'All');
  static String get masuk => _t('Masuk', 'Incoming');
  static String get keluar => _t('Keluar', 'Outgoing');
  static String get riwayatKosong => _t('Riwayat transaksi akan tampil di sini',
      'Transactions will show up here');
  static String get belumAdaRiwayat =>
      _t('Belum ada riwayat', 'No history yet');
  static String get riwayatSub => _t('Transaksi masuk dan keluar dompet ini',
      'Incoming and outgoing transactions for this wallet');
  static String get alamatTerpantau =>
      _t('Alamat terpantau', 'Watched address');

  // PIN
  static String get pinMin =>
      _t('PIN minimal 4 digit', 'PIN must be at least 4 digits');
  static String get pinSalah =>
      _t('PIN salah. Coba lagi.', 'Wrong PIN. Try again.');
  static String get bukaDompet => _t('Buka Dompet', 'Unlock wallet');
  static String get pinSubBiometrik => _t(
        'Gunakan sidik jari atau masukkan PIN untuk melanjutkan',
        'Use fingerprint or enter your PIN to continue',
      );
  static String get pinSub =>
      _t('Masukkan PIN untuk melanjutkan', 'Enter your PIN to continue');
  static String get buka => _t('Buka', 'Unlock');
  static String get gunakanSidikJari =>
      _t('Gunakan sidik jari', 'Use fingerprint');

  // Setelan
  static String get keamanan => _t('Keamanan', 'Security');
  static String get kunciAplikasi => _t('Kunci aplikasi', 'App lock');
  static String get kunciDesc =>
      _t('PIN 4-6 digit saat dibuka', '4-6 digit PIN on open');
  static String get ubahPIN => _t('Ubah PIN', 'Change PIN');
  static String get buatPIN => _t('Buat PIN', 'Create PIN');
  static String get ubah => _t('Ubah', 'Change');
  static String get buat => _t('Buat', 'Create');
  static String get bahasa => _t('Bahasa', 'Language');
  static String get tentang => _t('Tentang', 'About');
  static String get versiLabel => _t('Versi', 'Version');
  static String get node => _t('Node', 'Node');
  static String get frasaPemulihan =>
      _t('Frasa pemulihan 12 kata', '12-word recovery phrase');
  static String get frsaDesc => _t(
        'Cadangkan di tempat aman offline.\nTanpa cadangan, saldo tidak bisa dipulihkan.',
        'Back it up offline.\nWithout it, funds cannot be recovered.',
      );
  static String get cadangkan => _t('Cadangkan', 'Back up');
  static String get keluarAplikasi => _t('Keluar aplikasi', 'Exit app');
  static String get keluarDesc => _t('Tutup CEN Wallet', 'Close CEN Wallet');
  static String get setelanDompet => _t('Dompet', 'Wallet');
  static String get pinDompet => _t('PIN Dompet', 'Wallet PIN');
  static String get aktif => _t('Aktif', 'On');
  static String get belumDiatur => _t('Belum diatur', 'Not set');
  static String get hapusPIN => _t('Hapus PIN', 'Remove PIN');
  static String get hapusPINJudul => _t('Hapus PIN?', 'Remove PIN?');
  static String get hapusPINDesc => _t(
        'Menghapus PIN juga akan menonaktifkan buka kunci sidik jari. Dompet akan terbuka tanpa verifikasi.',
        'Removing the PIN also disables fingerprint unlock. The wallet will open without verification.',
      );
  static String get pinBaru => _t('PIN baru', 'New PIN');
  static String get konfirmasiPIN => _t('Konfirmasi PIN', 'Confirm PIN');
  static String get pinTidakCocok =>
      _t('Konfirmasi PIN tidak cocok', 'PIN confirmation does not match');
  static String get pinTersimpan => _t('PIN berhasil disimpan', 'PIN saved');
  static String get frasaDisalin =>
      _t('Frasa pemulihan disalin', 'Recovery phrase copied');
  static String get frasaTidakAda => _t('(tidak tersedia)', '(not available)');
  static String get frasaWarn => _t(
        'Simpan frasa ini secara offline. Siapa pun yang memilikinya dapat mengakses seluruh dana.',
        'Store this phrase offline. Anyone holding it can access all funds.',
      );
  static String get pinUbahDesc => _t(
        'PIN 4-6 digit untuk membuka dompet dan mengonfirmasi transaksi.',
        'A 4-6 digit PIN to unlock the wallet and confirm transfers.',
      );
  static String get biometrikBuka =>
      _t('Buka kunci sidik jari', 'Fingerprint unlock');
  static String get biometrikDesc => _t(
        'Gunakan sidik jari untuk buka dompet dan konfirmasi kirim',
        'Use fingerprint to unlock and confirm transfers',
      );
  static String get biometrikCatatan => _t(
        'Catatan: sidik jari dipakai untuk kenyamanan buka kunci. PIN tetap menjadi cadangan verifikasi.',
        'Note: fingerprint is for convenience. PIN remains the fallback verification.',
      );
  static String get biometrikButuhPIN => _t(
      'Buat PIN terlebih dahulu untuk mengaktifkan sidik jari',
      'Create a PIN first to enable fingerprint');
  static String get biometrikTidakTersedia => _t(
      'Sidik jari tidak tersedia di perangkat ini',
      'Fingerprint is not available on this device');
  static String get biometrikVerifikasi => _t(
      'Verifikasi sidik jari untuk mengaktifkan fitur ini',
      'Verify your fingerprint to enable this');
  static String get biometrikGagal =>
      _t('Verifikasi sidik jari gagal', 'Fingerprint verification failed');
  static String get biometrikCek =>
      _t('Memeriksa perangkat…', 'Checking device…');
  static String get biometrikNonaktif => _t(
      'Sidik jari/biometrik tidak tersedia di perangkat ini',
      'Fingerprint/biometrics unavailable on this device');
  static String get biometrikButuhPIN2 => _t(
      'Aktifkan PIN dulu untuk memakai sidik jari',
      'Enable a PIN first to use fingerprint');
  static String get jaringanAuto =>
      _t('Auto: celenium.web.id', 'Auto: celenium.web.id');
  static String get auto => 'Auto';
  static String get aplikasi => _t('Aplikasi', 'App');
  static String get aplikasiNama =>
      _t('Celenium Wallet (Desktop)', 'Celenium Wallet (Desktop)');
  static const appVersion = '1.0.2+3';
  static String get terlindungiPin => _t('Terlindungi PIN', 'PIN protected');
  static String get belumAdaPin => _t('Belum ada PIN', 'No PIN yet');

  // Scan QR
  static String get pindaiQRAlamat => _t('Pindai QR Alamat', 'Scan address QR');
  static String get senter => _t('Senter', 'Flashlight');
  static String get gantiKamera => _t('Ganti kamera', 'Switch camera');
  static String get tempel => _t('Tempel', 'Paste');
  static String get scanHint => _t(
        'Arahkan kamera ke kode QR alamat CEN. Alamat akan terisi otomatis.',
        'Point the camera at a CEN address QR. The address fills in automatically.',
      );

  // Desktop scan fallback
  static String get kameraDesktopTidakAda => _t(
        'Kamera langsung tidak tersedia di aplikasi desktop. Pindai QR dari gambar atau tempel alamatnya.',
        'Live camera is not available in the desktop app. Scan a QR image or paste the address instead.',
      );
  static String get pilihGambarQr => _t('Pilih gambar QR', 'Choose QR image');
  static String get pilihGambarDesc => _t(
        'Ambil tangkapan layar QR dari ponsel, lalu pilih file-nya di sini.',
        'Take a screenshot of the QR on your phone, then pick the file here.',
      );
  static String get gagalBacaQr => _t(
        'QR tidak terbaca. Coba gambar yang lebih tajam atau tempel alamat manual.',
        'Could not read that QR. Try a sharper image or paste the address manually.',
      );
  static String get tempelAlamatManual =>
      _t('Tempel alamat manual', 'Paste address manually');
  static String get atauTempel => _t('atau', 'or');
  static String get gunakan => _t('Gunakan', 'Use');

  // Login & multi-wallet
  static String get pilihDompet => _t('Pilih dompet', 'Choose a wallet');
  static String get pilihDompetSub => _t(
        'Dompet tersimpan di perangkat ini. Pilih satu untuk melanjutkan.',
        'Wallets saved on this device. Pick one to continue.',
      );
  static String get pinDesc => _t(
        'PIN 4-6 digit untuk membuka dompet dan mengonfirmasi transaksi.',
        'A 4-6 digit PIN opens the wallet and confirms transactions.',
      );
  static String get konfirmasiKirimDesc => _t(
        'Transaksi dikonfirmasi dengan sidik jari (jika aktif) atau PIN sebelum dikirim ke jaringan.',
        'Transactions are confirmed with a fingerprint (if enabled) or PIN before they reach the network.',
      );
  static String get pulihkanWallet =>
      _t('Pulihkan dengan 12 kata', 'Restore with 12 words');
  static String get pulihkanSub => _t(
        'Masukkan frasa pemulihan dompet lain. Frasa tidak dikirim ke mana pun.',
        'Enter the recovery phrase of another wallet. It never leaves this device.',
      );
  static String get importHint =>
      _t('kata1 kata2 … kata12', 'word1 word2 … word12');
  static String get restoreError => _t(
        'Kunci dompet tidak ditemukan di perangkat ini.',
        'This wallet has no key stored on this device.',
      );
  static String get masukDompet => _t('Masuk ke dompet', 'Open wallet');
  static String get fraseKosong =>
      _t('Frasa pemulihan belum diisi', 'Recovery phrase is empty');
  static String get loginNote => _t(
        'Kunci privat disimpan di keychain perangkat, bukan di server.',
        'Private keys live in the device keychain, never on a server.',
      );
  static String get tidakAdaDompet => _t(
        'Belum ada dompet tersimpan di perangkat ini.',
        'No wallets are saved on this device yet.',
      );

  // Logout
  static String get akun => _t('Akun', 'Account');
  static String get keluarAkun => _t('Keluar', 'Log out');
  static String get keluarAkunDesc => _t(
        'Kunci dompet ini dan kembali ke layar pilih dompet',
        'Lock this wallet and return to the wallet picker',
      );
  static String get keluarKonfirmasiJudul =>
      _t('Keluar dari dompet ini?', 'Log out of this wallet?');
  static String get keluarKonfirmasiMsg => _t(
        'Dompet tetap tersimpan di perangkat. Kamu bisa masuk lagi dengan PIN atau frasa pemulihan.',
        'The wallet stays on this device. You can sign back in with your PIN or recovery phrase.',
      );
  static String get yaKeluar => _t('Ya, keluar', 'Yes, log out');
  static String get ambilPindai => _t('Ambil & pindai', 'Capture & scan');
  static String get kameraTidakAda => _t(
      'Kamera tidak terdeteksi. Pilih gambar QR atau tempel alamat di bawah.',
      'No camera detected. Pick a QR image or paste the address below.');
  static String get kameraHintDesktop => _t(
      'Arahkan QR ke kamera, lalu tekan Ambil & pindai.',
      'Point the QR at the camera, then press Capture & scan.');
  static String get hapusPinWarning => _t(
      'Menghapus PIN juga menonaktifkan buka kunci sidik jari. Dompet akan terbuka tanpa verifikasi.',
      'Removing the PIN also turns off fingerprint unlock. The wallet will open without verification.');
  static String get biometrikBukaReason => _t(
      'Verifikasi sidik jari untuk membuka dompet CEN',
      'Verify your fingerprint to unlock the CEN wallet');

  // Wallet dashboard: navigation groups, empty states, address book.
  static String get nodeTerputus =>
      _t('Node tidak terjangkau', 'Node unreachable');
  static String get muatUlang => _t('Muat ulang', 'Refresh');
  static String get hariTerakhir => _t('hari terakhir', 'days back');
  static String get belumAdaAktivitas =>
      _t('Belum ada aktivitas', 'No activity yet');
  static String get aktivitasKosongBody => _t(
        'Transaksi masuk dan keluar akan tercatat di sini secara otomatis, lengkap dengan waktu dan alamat lawan transaksi.',
        'Incoming and outgoing transactions appear here automatically, with time and counterparty address.',
      );
  static String get aktivitasKosongHint => _t(
        'Saldo diperbarui dari jaringan setiap 15 detik.',
        'Balance refreshes from the network every 15 seconds.',
      );
  static String get lihatSemua => _t('Lihat semua', 'See all');
  static String get alamatTersimpan =>
      _t('Alamat tersimpan', 'Saved addresses');
  static String get alamatKosongJudul =>
      _t('Belum ada alamat tersimpan', 'No saved addresses yet');
  static String get alamatKosongBody => _t(
        'Simpan alamat yang sering dipakai supaya pengiriman berikutnya tidak perlu menyalin ulang.',
        'Keep the addresses you use often so the next send needs no copy-paste.',
      );
  static String get alamatKosongHint => _t(
        'Tekan Tambah untuk menyimpan alamat pertama.',
        'Press Add to save your first address.',
      );
  static String get labelAlamat => _t('Label', 'Label');
  static String get labelAlamatHint => _t('Contoh: Tabungan', 'e.g. Savings');
  static String get alamatTidakValid => _t(
        'Alamat CEN tidak valid untuk jaringan ini. Periksa awalan dan checksum-nya.',
        'Not a valid CEN address for this network. Check the prefix and checksum.',
      );
  static String get alamatTersimpanPesan =>
      _t('Alamat disimpan.', 'Address saved.');
  static String get hapusAlamatJudul =>
      _t('Hapus alamat ini?', 'Remove this address?');
  static String get hapusAlamatBody => _t(
        'Alamat hanya dihapus dari daftar di perangkat ini. Dana tidak terpengaruh.',
        'This only removes it from the list on this device. Funds are untouched.',
      );
  static String get kirimKeAlamat =>
      _t('Kirim ke alamat ini', 'Send to this address');
  static String get belumAdaRiwayatSaldo =>
      _t('Belum ada riwayat saldo', 'No balance history yet');

  static String get tidakTersedia => _t('Tidak tersedia', 'Unavailable');
  static String get riwayatSaldoHint => _t(
        'Grafik terbentuk setelah wallet mencatat beberapa bacaan saldo.',
        'The chart appears once the wallet has recorded a few balance readings.',
      );
  static String get cadangkanWallet =>
      _t('Cadangkan wallet', 'Back up your wallet');
  static String get cadangkanBody => _t(
        'Frasa 12 kata adalah satu-satunya cara memulihkan dana. Tanpa cadangan, wallet yang hilang tidak bisa dibuka lagi.',
        'The 12-word phrase is the only way to restore your funds. Without it a lost wallet cannot be reopened.',
      );
  static String get cadangkanSekarang =>
      _t('Cadangkan sekarang', 'Back up now');
  static String get sembunyikan => _t('Sembunyikan', 'Hide');
  static String get diagnostik => _t('Diagnostik', 'Diagnostics');
  static String get status => _t('Status', 'Status');
  static String get sinkron => _t('Sinkron', 'Synced');
  static String get terputus => _t('Terputus', 'Offline');
  static String get estimasiFee => _t('Estimasi fee', 'Estimated fee');
  static String get genesis => _t('Genesis', 'Genesis');
  static String get tambahAlamat => _t('Tambah', 'Add');
  static String terkirimTxid(String txid, int feePradha) => _t(
        'Terkirim. TXID: $txid · biaya $feePradha pradha',
        'Sent. TXID: $txid · fee $feePradha pradha',
      );
  static String get keluarAkunJudul =>
      _t('Keluar dari wallet ini?', 'Sign out of this wallet?');
  static String get keluarAkunBody => _t(
        'Frasa 12 kata tetap tersimpan aman. Kamu bisa masuk lagi dengan frasa itu atau membuka wallet lain di perangkat ini.',
        'Your 12-word phrase stays safe. You can sign back in with it or open another wallet on this device.',
      );
}
