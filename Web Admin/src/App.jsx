import React, { useState } from 'react';
import { 
  LayoutDashboard, Users, Utensils, AlertCircle, Settings, LogOut, TrendingUp, PackageCheck, X, BadgeCheck
} from 'lucide-react';
import './index.css';

// --- Dashboard Component ---
function DashboardScreen() {
  const recentDonations = [
    { id: 1, donor: 'Budi Santoso', item: 'Nasi Kotak Ayam (50 box)', status: 'Available', date: '26 Mei 2026' },
    { id: 2, donor: 'Sari Roti Jkt', item: 'Roti Tawar (100 bungkus)', status: 'Taken', date: '26 Mei 2026' },
  ];

  return (
    <>
      <header className="top-bar">
        <div>
          <h1>Overview Admin</h1>
          <p style={{ color: 'var(--text-muted)' }}>Selamat datang kembali, Super Admin!</p>
        </div>
      </header>

      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon green"><Utensils size={28} /></div>
          <div className="stat-details">
            <h3>Total Donasi</h3>
            <p>1,284</p>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon blue"><Users size={28} /></div>
          <div className="stat-details">
            <h3>Pengguna Aktif</h3>
            <p>5,492</p>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon yellow"><TrendingUp size={28} /></div>
          <div className="stat-details">
            <h3>Makanan Terselamatkan</h3>
            <p>3.2 Ton</p>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon purple"><BadgeCheck size={28} /></div>
          <div className="stat-details">
            <h3>User Terpercaya</h3>
            <p>148</p>
          </div>
        </div>
      </div>

      <section className="data-section">
        <div className="section-header">
          <h2>Aktivitas Donasi Terbaru</h2>
          <button className="action-btn">Lihat Semua</button>
        </div>
        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Donatur</th>
                <th>Item Makanan</th>
                <th>Tanggal</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {recentDonations.map((donation) => (
                <tr key={donation.id}>
                  <td>#{donation.id}</td>
                  <td style={{ fontWeight: 500 }}>{donation.donor}</td>
                  <td>{donation.item}</td>
                  <td>{donation.date}</td>
                  <td>
                    <span className={`status-badge ${donation.status.toLowerCase()}`}>
                      {donation.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </>
  );
}

// --- Donations Component ---
function DonationsScreen() {
  const donations = [
    { id: 101, donor: 'Ibu Ratna', receiver: '-', item: 'Sayur & Buah Segar', status: 'Available', date: '26 Mei 2026' },
    { id: 102, donor: 'KFC Sudirman', receiver: 'Panti Asuhan Kasih', item: 'Ayam Goreng Sisa Stok', status: 'Completed', date: '25 Mei 2026' },
    { id: 103, donor: 'Ahmad', receiver: '-', item: 'Beras 5kg', status: 'Available', date: '25 Mei 2026' },
  ];

  return (
    <>
      <header className="top-bar">
        <div>
          <h1>Data Donasi</h1>
          <p style={{ color: 'var(--text-muted)' }}>Manajemen semua postingan donasi makanan</p>
        </div>
      </header>

      <section className="data-section">
        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Donatur</th>
                <th>Penerima</th>
                <th>Item Makanan</th>
                <th>Status</th>
                <th>Aksi</th>
              </tr>
            </thead>
            <tbody>
              {donations.map((doc) => (
                <tr key={doc.id}>
                  <td>#{doc.id}</td>
                  <td style={{ fontWeight: 500 }}>{doc.donor}</td>
                  <td>{doc.receiver}</td>
                  <td>{doc.item}</td>
                  <td>
                    <span className={`status-badge ${doc.status.toLowerCase()}`}>
                      {doc.status}
                    </span>
                  </td>
                  <td>
                    <button className="action-btn danger">Hapus Post</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </>
  );
}

// --- Users Component ---
function UsersScreen() {
  const users = [
    { id: 1, name: 'Panti Asuhan Kasih', type: 'NGO', donations: 45, reports: 0, status: 'Terpercaya', date: '10 Mei 2026' },
    { id: 2, name: 'Sari Roti Jkt', type: 'Donatur', donations: 12, reports: 0, status: 'Biasa', date: '15 Mei 2026' },
    { id: 3, name: 'Budi Santoso', type: 'Penerima', donations: 3, reports: 2, status: 'Biasa', date: '20 Jan 2026' },
  ];

  return (
    <>
      <header className="top-bar">
        <div>
          <h1>Pengguna Aplikasi</h1>
          <p style={{ color: 'var(--text-muted)' }}>Pantau reputasi dan aktivitas pengguna</p>
        </div>
      </header>

      <section className="data-section">
        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Nama Pengguna</th>
                <th>Tipe Akun</th>
                <th>Donasi Berhasil</th>
                <th>Laporan</th>
                <th>Reputasi</th>
                <th>Aksi</th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => (
                <tr key={u.id}>
                  <td style={{ fontWeight: 500 }}>{u.name}</td>
                  <td>{u.type}</td>
                  <td style={{ textAlign: 'center' }}>{u.donations}x</td>
                  <td style={{ textAlign: 'center', color: u.reports > 0 ? '#ef4444' : 'inherit', fontWeight: u.reports > 0 ? 'bold' : 'normal' }}>
                    {u.reports}
                  </td>
                  <td>
                    {u.status === 'Terpercaya' ? (
                      <span className="status-badge terpercaya">
                        <BadgeCheck size={14} /> Terpercaya
                      </span>
                    ) : (
                      <span className="status-badge biasa">Biasa</span>
                    )}
                  </td>
                  <td style={{ display: 'flex', gap: '8px' }}>
                    {u.status === 'Terpercaya' ? (
                      <button className="action-btn" style={{color: 'var(--text-muted)'}}>Hapus Badge</button>
                    ) : (
                      <button className="action-btn blue">Jadikan Terpercaya</button>
                    )}
                    <button className="action-btn danger">Blokir</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </>
  );
}

// --- Reports Component ---
function ReportsScreen() {
  const reports = [
    { id: 1, reporter: 'Panti Asuhan Kasih', target: 'KFC Sudirman', issue: 'Makanan sudah basi saat diambil', status: 'Open' },
    { id: 2, reporter: 'Ahmad', target: 'Budi Santoso', issue: 'Penerima tidak datang mengambil donasi', status: 'Resolved' },
  ];

  return (
    <>
      <header className="top-bar">
        <div>
          <h1>Laporan Masalah</h1>
          <p style={{ color: 'var(--text-muted)' }}>Tindak lanjuti keluhan dan berikan penalti</p>
        </div>
      </header>

      <section className="data-section">
        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Pelapor</th>
                <th>Dilaporkan</th>
                <th>Masalah (Keluhan)</th>
                <th>Status</th>
                <th>Aksi</th>
              </tr>
            </thead>
            <tbody>
              {reports.map((r) => (
                <tr key={r.id}>
                  <td style={{ fontWeight: 500 }}>{r.reporter}</td>
                  <td style={{ fontWeight: 500, color: '#dc2626' }}>{r.target}</td>
                  <td>{r.issue}</td>
                  <td>
                    <span className={`status-badge ${r.status.toLowerCase()}`}>
                      {r.status}
                    </span>
                  </td>
                  <td>
                    {r.status === 'Open' ? (
                      <button className="action-btn danger">Beri Penalti (+1 Laporan)</button>
                    ) : (
                      <button className="action-btn" style={{color: 'var(--text-muted)'}}>Lihat Detail</button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </>
  );
}

// --- Settings Component ---
function SettingsScreen() {
  return (
    <>
      <header className="top-bar">
        <div>
          <h1>Pengaturan</h1>
          <p style={{ color: 'var(--text-muted)' }}>Konfigurasi sistem dan akun admin</p>
        </div>
      </header>

      <div className="settings-grid">
        {/* Profile Settings */}
        <section className="data-section">
          <div className="section-header">
            <h2>Profil Admin</h2>
          </div>
          <div className="form-group">
            <label>Nama Tampilan</label>
            <input type="text" defaultValue="Adminstrator Utama" />
          </div>
          <div className="form-group">
            <label>Email Kontak</label>
            <input type="email" defaultValue="admin@fooddonation.id" />
          </div>
          <div className="form-group" style={{ marginTop: '24px' }}>
            <label>Password Baru</label>
            <input type="password" placeholder="Masukkan password baru" />
          </div>
          <button className="btn-primary" style={{ marginTop: '16px' }}>Simpan Perubahan</button>
        </section>

        {/* Categories Settings */}
        <section className="data-section">
          <div className="section-header">
            <h2>Kategori Donasi Makanan</h2>
          </div>
          <div style={{ marginBottom: '24px' }}>
            <span className="category-tag">Makanan Berat <button><X size={14}/></button></span>
            <span className="category-tag">Bahan Mentah <button><X size={14}/></button></span>
            <span className="category-tag">Roti & Kue <button><X size={14}/></button></span>
            <span className="category-tag">Sayur & Buah <button><X size={14}/></button></span>
          </div>
          
          <div className="form-group">
            <label>Tambah Kategori Baru</label>
            <div style={{ display: 'flex', gap: '12px' }}>
              <input type="text" placeholder="Nama kategori..." />
              <button className="btn-primary">Tambah</button>
            </div>
          </div>
        </section>

        {/* App Configuration */}
        <section className="data-section" style={{ gridColumn: '1 / -1' }}>
          <div className="section-header">
            <h2>Konfigurasi Aplikasi</h2>
          </div>
          <div className="form-group">
            <label>Waktu Default Kedaluwarsa Postingan (Jam)</label>
            <input type="number" defaultValue="24" style={{ maxWidth: '200px' }} />
          </div>
          <div className="form-group">
            <label>Link WhatsApp Bantuan (CS)</label>
            <input type="text" defaultValue="https://wa.me/6281234567890" />
          </div>
          <button className="btn-primary" style={{ marginTop: '16px' }}>Simpan Konfigurasi</button>
        </section>
      </div>
    </>
  );
}


// --- Main App Container ---
function App() {
  const [activeTab, setActiveTab] = useState('dashboard');

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard': return <DashboardScreen />;
      case 'donations': return <DonationsScreen />;
      case 'users': return <UsersScreen />;
      case 'reports': return <ReportsScreen />;
      case 'settings': return <SettingsScreen />;
      default: return <DashboardScreen />;
    }
  };

  return (
    <div className="app-container">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-header">
          <Utensils size={28} color="#10b981" />
          <h2>FoodAdmin</h2>
        </div>
        <nav className="nav-links">
          <button 
            className={`nav-item ${activeTab === 'dashboard' ? 'active' : ''}`}
            onClick={() => setActiveTab('dashboard')}
          >
            <LayoutDashboard size={20} /> Dashboard
          </button>
          <button 
            className={`nav-item ${activeTab === 'donations' ? 'active' : ''}`}
            onClick={() => setActiveTab('donations')}
          >
            <Utensils size={20} /> Data Donasi
          </button>
          <button 
            className={`nav-item ${activeTab === 'users' ? 'active' : ''}`}
            onClick={() => setActiveTab('users')}
          >
            <Users size={20} /> Pengguna
          </button>
          <button 
            className={`nav-item ${activeTab === 'reports' ? 'active' : ''}`}
            onClick={() => setActiveTab('reports')}
          >
            <AlertCircle size={20} /> Laporan Masalah
          </button>
          <button 
            className={`nav-item ${activeTab === 'settings' ? 'active' : ''}`}
            onClick={() => setActiveTab('settings')}
            style={{ marginTop: 'auto' }}
          >
            <Settings size={20} /> Pengaturan
          </button>
          <button className="nav-item" style={{ color: '#ef4444' }}>
            <LogOut size={20} /> Keluar
          </button>
        </nav>
      </aside>

      {/* Main Content */}
      <main className="main-content">
        {renderContent()}
      </main>
    </div>
  );
}

export default App;
