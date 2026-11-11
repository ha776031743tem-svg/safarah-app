-- Safarah: expand canonical daily attendance states.
-- Apply once to an existing Supabase project.
ALTER TABLE public.daily_logs
  DROP CONSTRAINT IF EXISTS daily_logs_status_check;

UPDATE public.daily_logs
SET status = 'present'
WHERE status = 'recited';

UPDATE public.daily_logs
SET status = 'attended_no_recite'
WHERE status = 'attended_no_recitation';

ALTER TABLE public.daily_logs
  ADD CONSTRAINT daily_logs_status_check
  CHECK (status IN ('present', 'absent', 'attended_no_recite', 'excused'));
