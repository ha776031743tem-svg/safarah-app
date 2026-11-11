@echo off
chcp 65001 >nul
title Safarah App Builder - بناء تطبيق سفرة
echo ============================================================================
echo        مشروع تطبيق "سَفَرَة" (Safarah) لإدارة حلقات تحفيظ القرآن الكريم
echo ============================================================================
echo.

where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [خطأ] لم يتم العثور على Flutter في متغيرات النظام PATH.
    echo يرجى التأكد من تثبيت Flutter SDK وإضافته إلى PATH ثم إعادة المحاولة.
    pause
    exit /b 1
)

if not exist "android" (
    echo [1/4] جاري توليد ملفات منصة الأندرويد الأساسية...
    call flutter create --platforms=android --org com.safarah.quran .
) else (
    echo [1/4] مجلد android موجود مسبقاً.
)

echo.
echo [2/4] جاري تحميل وتثبيت الحزم والمكتبات (flutter pub get)...
call flutter pub get

echo.
echo [3/4] جاري بناء ملف الـ APK النهائي بصيغة Release...
call flutter build apk --release

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo.
    echo [4/4] تم بناء ملف app-release.apk بنجاح! جاري فتح مجلد المخرجات...
    explorer "build\app\outputs\flutter-apk"
) else (
    echo.
    echo [تنبيه] لم يتم العثور على ملف الـ APK، يرجى مراجعة رسائل البناء أعلاه.
)

echo.
pause
