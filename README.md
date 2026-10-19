# Catfish Farm V2 — GitHub Pages + Supabase

เว็บแอปภาษาไทย ใช้บนมือถือ แยกโหมดพ่อ (บันทึกง่าย) และเจ้าของ (ต้นทุน/รอบเลี้ยง/กำไร) สร้างต่อจากแนวคิด V1 แต่เป็นโค้ดใหม่รองรับฐานข้อมูลร่วมกัน

## ตั้งค่า (ต้องทำครั้งเดียว)

1. สร้างโปรเจกต์ที่ https://supabase.com/dashboard (เลือก Region ใกล้ไทย)
2. เปิด **SQL Editor** แล้ววางเนื้อหา `supabase.sql` และ Run
3. ไปที่ **Project Settings → API** หรือ **Connect** คัดลอก **Project URL** และ **Publishable key** (`sb_publishable_...`) หรือ legacy `anon key` เท่านั้น **ห้ามใช้ service_role / secret key**
4. ไปที่ **Authentication → Providers → Email** และเปิดการสมัครด้วย email/password; ถ้าเปิด Confirm email จะต้องคลิกลิงก์ยืนยันก่อน
5. ใน Supabase **Authentication → URL Configuration** เพิ่ม URL GitHub Pages ของคุณใน Redirect URLs / Site URL ตามความจำเป็น (โดยเฉพาะถ้าใช้ confirmation email)
6. สร้าง GitHub repo แล้วอัปโหลด `index.html` ที่ root → **Settings → Pages → Deploy from a branch → main / (root)**
7. เปิดหน้าเว็บ GitHub Pages บนมือถือ กรอก URL + publishable key ที่หน้าเริ่มต้น (เก็บไว้ใน browser ของเครื่องนั้น)
8. เจ้าของลงทะเบียนและสร้างฟาร์ม จากนั้นไปเมนู **เจ้าของ → รหัสเชิญ** ส่งให้พ่อ พ่อลงทะเบียนบนมือถือของตัวเองและกด **เข้าร่วมฟาร์ม**
9. เจ้าของเพิ่มรอบเลี้ยงแรก แล้วพ่อเริ่มบันทึกอาหารและอาการปลา

> เว็บ GitHub Pages สาธารณะได้ แต่ข้อมูลถูกป้องกันด้วย Supabase Auth + Row Level Security. เก็บรหัสผ่านเป็นความลับ แชร์รหัสเชิญเฉพาะคนที่ไว้ใจ เพราะผู้ถือรหัสสมัครเป็นผู้ดูแลและเพิ่มบันทึกได้

## คุณสมบัติ
- โหมดพ่อ: ปุ่มให้อาหารเช้า/เย็น, ปลาตาย, ตรวจปั๊ม, สุ่มชั่ง, จับขาย
- โหมดเจ้าของ: Batch Management คัดลอกค่าตั้งต้นรอบก่อน, รายจ่าย, อุปกรณ์ลงทุนระยะยาว
- คุณภาพน้ำ/กรอง: บันทึกปริมาณเปลี่ยนน้ำ pH TAN ไนไตรต์ และงานดูแลกรอง
- Dashboard: ปลาคงเหลือ อาหารสะสม ต้นทุนดำเนินงาน รายได้ กำไร FCR ประมาณ ราคาขายคุ้มทุน
- V1 Import: นำเข้า backup JSON จาก V1 ไปยังรอบที่เลือก เพียงครั้งเดียว (ต้องตรวจความซ้ำด้วยตนเอง)
- CSV Export, เซิร์ฟเวอร์ฐานข้อมูลซิงก์ข้ามเครื่อง (รีโหลดเพื่อดูข้อมูลล่าสุด)

## แนวทางบัญชี
- อุปกรณ์เป็นต้นทุนลงทุนแยก ไม่หักจากกำไรดำเนินงาน
- การให้อาหารบันทึกต้นทุน **ตามอาหารที่ใช้จริง** × ราคากก. (อย่านับยอดซื้อกระสอบซ้ำ)
- ต้นทุนลูกปลาที่กรอกในการสร้างรอบถูกนับ 1 ครั้ง ไม่ลงในรายจ่ายซ้ำ
- แนะนำบันทึกค่าคงที่ น้ำ/ไฟ และค่าแรงตามจริง
- สูตร FCR **ประมาณการ** = อาหารสะสม ÷ [(ชีวมวลปลาคงเหลือจากการสุ่มชั่งล่าสุด + น้ำหนักที่จับขายสะสม) − น้ำหนักลูกปลาเริ่มต้น] ไม่ชดเชยอาหารที่ปลาตายกินไปและความต่างน้ำหนักตอนขาย/ตายทั้งหมด
- ราคาขายขั้นต่ำใช้ต้นทุนบันทึกแล้วและน้ำหนักปลาที่คาดว่าจะจับขายเพิ่ม หักยอดขายที่ผ่านมา; **ต้องบวกต้นทุนอนาคตที่ยังไม่เกิดเองในการประเมินก่อนขายจริง**

## ข้อจำกัด/ความปลอดภัย
- ต้องเชื่อมอินเทอร์เน็ตขณะบันทึก ไม่ใช่แอปออฟไลน์
- จำนวนปลาเป็นประมาณจากเริ่มรอบ − จับขาย − ตาย; ยังไม่มีระบบนับปลาอัตโนมัติ
- ค่าโปรตีน, อัตราให้อาหาร, คุณภาพน้ำต้องเลือกตามคำแนะนำผู้เลี้ยงและผลตรวจจริง
- ระบบกรองชีวภาพต้องมีเวลาตั้งตัวและมีอากาศเพียงพอ ไม่มีสูตรเปลี่ยนน้ำตายตัว
- โครง PVC/บ่อผ้าใบต้องผ่านการยืนยันความแข็งแรงก่อนใช้งานจริง
- เพื่อความปลอดภัย ควรเปิด Supabase Database backups ตามแผนที่รองรับและส่งออก CSV เป็นระยะ
- เจ้าของควรทดสอบ SQL/RLS กับบัญชีพ่อและบัญชีอื่นที่ไม่ได้รับเชิญ ก่อนใช้ข้อมูลจริง

## V2.1 — 19 October 2026

- โหลดรายการแบบแบ่งหน้าและกรองรอบที่ฐานข้อมูล ป้องกันยอดสะสมขาดเมื่อเกิน 1,000 รายการ
- เรียงตามวันที่รายการก่อนเวลาบันทึก และใช้วันที่ประเทศไทย
- ป้องกันการกดบันทึกซ้ำระหว่างรอ และแจ้งแยกเมื่อบันทึกสำเร็จแต่รีโหลดล้มเหลว
- ปฏิเสธ secret/service_role key, ป้องกันสูตรอันตรายใน CSV, ตรวจจำนวนปลาเป็นจำนวนเต็ม
- นำเข้า V1 ด้วยคำขอเดียวเพื่อให้สำเร็จหรือยกเลิกทั้งชุด ตรวจวันที่ ตัวเลข และรายการซ้ำก่อนส่ง (การตรวจซ้ำฝั่งเว็บไม่รับประกันกรณีหลายเครื่องนำเข้าพร้อมกัน)
- แสดงจำนวนปลาตาย/ขายในประวัติ และสถานะอัปเดตล่าสุด

### Development and release

Run `node --test tests/regression.cjs` with Node.js 22 or newer before publishing. Commit changes to `main`; the existing GitHub Pages branch deployment publishes the root `index.html`. Check the Pages Actions run and verify the live version label. No manual file upload is needed.

**Data safety:** Keep the current Supabase project, localStorage configuration keys, Auth, tables and RLS. Updating the static site does not require running `supabase.sql` again. Never run migrations, reset data, change RLS or execute production writes during testing without checking the current database and obtaining the owner's approval. The SQL file is original setup, not a rerunnable migration. This release does not modify it.

Regression tests use mocks and do not access production Supabase. Live authentication, cross-account RLS and actual database configuration require a separately authorized test environment/session; repository code alone cannot verify the deployed database policies. Roll back application code through a new Git commit reverting the release; do not reset or restore the database for a frontend rollback.

## V2.2 — Centered mobile menu

The first signed-in screen is a centered menu with large cards for daily records, overview, water/filter care, history, and owner management. Phone layouts use two columns; larger screens use three. Each section has a sticky return-to-menu button, a clear heading, keyboard focus styling, and screen-reader-friendly navigation. Caregivers do not see the owner card. This is a frontend-only change and requires no database migration.
