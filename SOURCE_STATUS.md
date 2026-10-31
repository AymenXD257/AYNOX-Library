# AYNOX Library — Source Status & Verification Report

Every integrated book source has been verified according to official APIs, OPDS feeds, licensing rules, and access restrictions.

| Provider Name | Integrated? | Search Tested? | Download Tested? | Scanned PDF? | EPUB Available? | Arabic Books? | Borrowing Restrictions? | Test Result |
|---|---|---|---|---|---|---|---|---|
| **Project Gutenberg** (`gutendex`) | **Yes** | **Yes** (MockClient & Live API) | **Yes** | No (Clean digital text) | **Yes** (EPUB 3 / Standard) | Very limited (few historical texts) | None (100% Public domain) | **HEALTHY / ONLINE** |
| **Open Library** (`open_library`) | **Yes** | **Yes** (MockClient & Live API) | **Yes** (via IA links) | **Yes** (via IA archive) | **Yes** | **Yes** (Arabic catalog records) | Physical records marked as non-downloadable; borrowable books clearly designated | **HEALTHY / ONLINE** |
| **Internet Archive** (`internet_archive`) | **Yes** | **Yes** (MockClient & Live API) | **Yes** (Direct download URLs) | **Yes** (Original scans) | **Yes** | **Yes** (Extensive Arabic heritage collections) | DRM/Controlled digital lending books excluded; only public-domain & open access indexed | **HEALTHY / ONLINE** |
| **Standard Ebooks** (`standard_ebooks`) | **Yes** | **Yes** (Curated catalog & OPDS) | **Yes** (Direct verified URLs) | No | **Yes** (Highest typography standards) | No | None (100% Free Public domain) | **HEALTHY / ONLINE** |
| **Arabic Heritage Repositories** (`arabic_heritage`) | **Yes** | **Yes** (Curated + IA Arabic) | **Yes** (Tested direct links) | **Yes** | Planned in next batch | **Yes** (Exclusively Arabic heritage) | None (Public domain heritage & open-access) | **HEALTHY / ONLINE** |
| **Directory of Open Access Books** (`doab`) | **Yes** | **Yes** (REST API) | **Yes** (Direct PDF links) | **Yes** (Monographs) | Limited | Selected university publications | Open Access (Creative Commons / CC-BY) | **HEALTHY / ONLINE** |
| **Local Storage** (`local_storage`) | **Yes** | **Yes** (Device picker) | N/A (Direct file copy) | **Yes** | **Yes** | **Yes** | User-owned files only | **HEALTHY / ONLINE** |

### Legal & Ethical Compliance Summary:
- **No Piracy Sites:** Zero integration with illegal sites (LibGen, Z-Library, Sci-Hub).
- **No DRM Bypassing:** Lending-restricted books on Open Library are marked as physical or preview only; never downloaded unlawfully.
- **Provider Terms & Rate Limiting:** All requests specify a custom user agent (`AYNOX-Library/1.0.0`), accept timeouts (8-12s), and use concurrency with retry backoffs.
- **Honest Attribution:** Every book card clearly displays its originating provider and rights status.
