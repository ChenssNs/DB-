CREATE OR REPLACE FUNCTION set_task_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tasks_set_updated_at
BEFORE UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION set_task_updated_at();

CREATE OR REPLACE FUNCTION inc_task_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE tasks
    SET comments_count = comments_count + 1
    WHERE id = NEW.task_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_task_comments_inc_count
AFTER INSERT ON task_comments
FOR EACH ROW
EXECUTE FUNCTION inc_task_comments_count();