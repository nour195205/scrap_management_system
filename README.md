# برنامج ميزاني (Mizany App) ⚖️

نظام متكامل لإدارة محلات وتجارة الخردة (حديد، نحاس، كرتون، إلخ) يعمل كتطبيق سطح مكتب (Desktop Application) أوفلاين بالكامل لضمان سرعة الأداء وسرية البيانات.

## 🎥 فيديو توضيحي للمشروع (Demo)
شاهد طريقة عمل البرنامج وتفاصيل الواجهة من هنا:
[![Mizany App Demo](https://img.youtube.com/vi/RyS4XPO-e-Q/0.jpg)](https://youtu.be/RyS4XPO-e-Q)

## ✨ أهم المميزات
* **إدارة المخزون:** متابعة دقيقة للأوزان (بالكيلو والطن) والكميات المتاحة لكل صنف.
* **المبيعات والمشتريات:** تسجيل الحركات المالية وحساب صافي الربح الفعلي لكل عملية بيع بناءً على سعر الشراء.
* **إدارة الخزنة:** متابعة حية ومستمرة لرأس المال.
* **التقارير والإحصائيات:** استخراج التقارير وتصديرها بصيغة PDF أو Excel لمراجعة حركة الشغل (يومي، شهري، سنوي).
* **دعم الأوفلاين:** قاعدة بيانات محلية لا تحتاج للاتصال بالإنترنت.

## 🛠️ التقنيات المستخدمة (Tech Stack)
* **Frontend:** Flutter (Dart)
* **Database:** SQLite (sqflite_common_ffi)
* **Desktop Support:** Windows App Build
* **Packaging:** Inno Setup (.exe Installer)

## 📄 التوثيق (Documentation)
يحتوي مجلد `docs` المرفق في هذا المستودع على مستندات المشروع، وتشمل وثيقة متطلبات المستخدم (User Requirements) ومتطلبات النظام (System Requirements).

## 🚀 طريقة التشغيل للمطورين (Run Locally)

1. قم بعمل استنساخ (Clone) للمستودع:
   ```bash
   git clone [https://github.com/nour195205/scrap_management_system.git](https://github.com/nour195205/scrap_management_system.git)
   ```
2. قم بتحميل الاعتمادات والمكتبات:
   ```bash
   flutter pub get
   ```
3. لتشغيل البرنامج على نظام تشغيل ويندوز:
   ```bash
   flutter run -d windows
   ```
4. لاستخراج نسخة نهائية للعميل (Production):
   ```bash
   flutter build windows
   ```
