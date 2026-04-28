# Journal-Project-ETS-PPB-D
## Deskripsi Singkat
Project yang saya buat berbentuk **Online Journal**. Sesuai namanya, jurnal ini memfasilitasi user untuk menulis jurnal (CRUD) dengan praktis dan mudah. Dengan utilisasi menggunakan authentication email dan password, user dapat menulis jurnal dengan aman dan privat. Jurnal ini juga memiliki fitur note-sharing dengan user lain sehingga memudahkan user untuk merekam memori bersama orang terdekat. Fitur lain seperti kustomisasi profil user dan daily reminder notification pun diberikan demi kenyamanan user dalam mencurahkan kesehariannya.


Tanpa perlu mengkhawatirkan memori lokal perangkat, jurnal ini sudah terintegrasi dengan cloud storage Firebase (Firestore) yang menyimpan data user, jurnal yang ditulis, serta media yang diupload.
<img width="1386" height="553" alt="image" src="https://github.com/user-attachments/assets/4c8b43fe-e190-415b-b514-04f77c4109d7" />
<img width="1372" height="883" alt="image" src="https://github.com/user-attachments/assets/9ed0943b-17cb-4e70-9aa0-0f0b83030223" />
<img width="1395" height="310" alt="image" src="https://github.com/user-attachments/assets/4ff2f77d-6221-464b-aee2-f76f15de1439" />

## Fitur yang Diberikan
1. CRUD with media
2. Autentikasi (email)
3. Multi-user journaling dengan pengguna lain yang sudah terdaftar
4. Daily reminder notification
5. Profile customisation
6. Cloud storage

## Rincian Relasional
1. One-to-one:
- Auth (1 user 1 akun email)
- 1 invite ID hanya menyangkut di 1 jurnal dan 1 user

2. One-to-many:
- 1 user banyak jurnal
- 1 host banyak invitations
- 1 jurnal banyak invitations

3. Many-to-many:
- Banyak user ke banyak jurnal: 1 jurnal banyak user, 1 user banyak jurnal (notes-sharing)

## Video Demo
sss
