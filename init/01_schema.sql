CREATE TABLE users (
    id              SERIAL PRIMARY KEY,
    email           VARCHAR(255) NOT NULL UNIQUE,
    full_name       VARCHAR(255) NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

CREATE TABLE projects (
    id              SERIAL PRIMARY KEY,
    owner_id        INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    deadline        DATE,
    CONSTRAINT chk_project_name_len CHECK (char_length(name) >= 3 AND char_length(name) <= 255)
);

CREATE TABLE task_statuses (
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(50) NOT NULL UNIQUE,
    name        VARCHAR(100) NOT NULL,
    color       VARCHAR(7) DEFAULT '#CCCCCC' -- HEX для фронтенда
);

CREATE TABLE task_priorities (
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(50) NOT NULL UNIQUE,
    name        VARCHAR(100) NOT NULL,
    weight      INTEGER NOT NULL DEFAULT 1 CHECK (weight > 0)
);

CREATE TABLE tasks (
    id              SERIAL PRIMARY KEY,
    project_id      INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    author_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    assignee_id     INTEGER REFERENCES users(id) ON DELETE SET NULL,
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    status_id       INTEGER NOT NULL REFERENCES task_statuses(id),
    priority_id     INTEGER NOT NULL REFERENCES task_priorities(id),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    due_date        DATE,
    estimate_hours  NUMERIC(5,2) CHECK (estimate_hours IS NULL OR estimate_hours >= 0),
    comments_count  INTEGER NOT NULL DEFAULT 0 CHECK (comments_count >= 0),
    CONSTRAINT chk_title_len CHECK (char_length(title) >= 3 AND char_length(title) <= 255)
);

CREATE TABLE task_comments (
    id              SERIAL PRIMARY KEY,
    task_id         INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    author_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    body            TEXT NOT NULL CHECK (char_length(body) >= 5),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);
=====
CREATE INDEX idx_projects_owner_id ON projects(owner_id);
CREATE INDEX idx_tasks_project_id ON tasks(project_id);
CREATE INDEX idx_tasks_author_id ON tasks(author_id);
CREATE INDEX idx_tasks_assignee_id ON tasks(assignee_id);
CREATE INDEX idx_tasks_status_id ON tasks(status_id);
CREATE INDEX idx_tasks_priority_id ON tasks(priority_id);
CREATE INDEX idx_task_comments_task_id ON task_comments(task_id);
CREATE INDEX idx_task_comments_author_id ON task_comments(author_id);

CREATE INDEX idx_tasks_due_date ON tasks(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_tasks_created_at ON tasks(created_at);
CREATE INDEX idx_users_email ON users(email) WHERE is_active = true;

CREATE INDEX idx_tasks_project_status ON tasks(project_id, status_id);

====

CREATE OR REPLACE FUNCTION check_project_authority()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.project_id IS NOT NULL AND NEW.author_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM projects p 
            WHERE p.id = NEW.project_id AND p.owner_id = NEW.author_id
        ) THEN
            RAISE EXCEPTION 'User % cannot create tasks in project % (not owner)', 
                NEW.author_id, NEW.project_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_project_authority
    BEFORE INSERT OR UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION check_project_authority();
