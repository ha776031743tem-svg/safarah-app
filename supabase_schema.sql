-- ============================================================================
-- مشروع "سَفَرَة" (Safarah) - مخطط قاعدة بيانات Supabase (PostgreSQL)
-- ============================================================================

-- 1. جدول المستخدمين (المدراء، المعلمين التابعين، المعلمين المستقلين)
CREATE TABLE IF NOT EXISTS public.users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'managed_teacher', 'independent_teacher')),
    halqa_name TEXT DEFAULT '',
    admin_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. جدول الطلاب
CREATE TABLE IF NOT EXISTS public.students (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    teacher_id TEXT NOT NULL,
    admin_id TEXT,
    halqa_name TEXT DEFAULT '',
    parent_phone TEXT DEFAULT '',
    last_surah_number INTEGER DEFAULT 1,
    last_surah_name TEXT DEFAULT 'الفاتحة',
    last_ayah INTEGER DEFAULT 1,
    last_page INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. جدول السجلات اليومية (الحفظ، المراجعة، الغياب، الحضور بدون تسميع)
CREATE TABLE IF NOT EXISTS public.daily_logs (
    id TEXT PRIMARY KEY,
    student_id TEXT NOT NULL,
    teacher_id TEXT NOT NULL,
    admin_id TEXT,
    log_date TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('present', 'absent', 'attended_no_recite', 'excused')),
    mem_surah_number INTEGER,
    mem_surah_name TEXT,
    mem_from_ayah INTEGER,
    mem_to_ayah INTEGER,
    mem_from_page INTEGER,
    mem_to_page INTEGER,
    rev_surah_number INTEGER,
    rev_surah_name TEXT,
    rev_from_ayah INTEGER,
    rev_to_ayah INTEGER,
    rev_from_page INTEGER,
    rev_to_page INTEGER,
    notes TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- فهارس لتسريع عمليات البحث والمزامنة
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_admin_id ON public.users(admin_id);
CREATE INDEX IF NOT EXISTS idx_students_teacher_id ON public.students(teacher_id);
CREATE INDEX IF NOT EXISTS idx_students_admin_id ON public.students(admin_id);
CREATE INDEX IF NOT EXISTS idx_logs_student_id ON public.daily_logs(student_id);
CREATE INDEX IF NOT EXISTS idx_logs_teacher_id ON public.daily_logs(teacher_id);
CREATE INDEX IF NOT EXISTS idx_logs_admin_id ON public.daily_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_logs_date ON public.daily_logs(log_date);

-- تفعيل الوصول السريع (اختياري: تعطيل RLS لتسهيل الربط المباشر عبر مفتاح Anon في النموذج الأولي)
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.students DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_logs DISABLE ROW LEVEL SECURITY;

-- ترحيل آمن للبيانات المنشأة بالإصدارات السابقة
ALTER TABLE public.daily_logs DROP CONSTRAINT IF EXISTS daily_logs_status_check;
UPDATE public.daily_logs SET status = 'present' WHERE status = 'recited';
UPDATE public.daily_logs SET status = 'attended_no_recite' WHERE status = 'attended_no_recitation';
ALTER TABLE public.daily_logs ADD CONSTRAINT daily_logs_status_check
  CHECK (status IN ('present', 'absent', 'attended_no_recite', 'excused'));
