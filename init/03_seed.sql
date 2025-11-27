INSERT INTO task_statuses (code, name, color) VALUES
 ('new', 'Новая', '#E3F2FD'),
 ('in_progress', 'В работе', '#FFF3E0'), 
 ('review', 'На проверке', '#F3E5F5'),
 ('done', 'Сделана', '#E8F5E8'),
 ('blocked', 'Заблокирована', '#FFEBEE')
ON CONFLICT (code) DO NOTHING;

INSERT INTO task_priorities (code, name, weight) VALUES
 ('low', 'Низкий', 1),
 ('medium', 'Средний', 3),
 ('high', 'Высокий', 5),
 ('critical', 'Критический', 10)
ON CONFLICT (code) DO NOTHING;

INSERT INTO users (email, full_name)
SELECT format('student%s@edu.ru', generate_series(1,25)),
       format('Студент %s Иванов', generate_series(1,25))
ON CONFLICT DO NOTHING;

INSERT INTO projects (owner_id, name, description, deadline)
SELECT 
    (1 + trunc(random()*24)::int),  -- случайный владелец
    format('Курсовая %s', i),
    format('Разработка веб-приложения %s', i),
    CURRENT_DATE + (30 + i*7)::int
FROM generate_series(1,8) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO tasks (
    project_id, author_id, assignee_id, title, description,
    status_id, priority_id, due_date, estimate_hours
)
SELECT 
    (1 + trunc(random()*7)::int),      -- случайный проект
    (1 + trunc(random()*24)::int),     -- автор
    (1 + trunc(random()*24)::int),     -- исполнитель
    format('Реализовать %s #%s', 
           ARRAY['авторизацию','CRUD','API','тесты','UI'][1+trunc(random()*4)::int], i),
    format('Детальная реализация модуля %s', i),
    (1 + trunc(random()*4)::int),      -- статус
    (1 + trunc(random()*3)::int),      -- приоритет
    CURRENT_DATE + trunc(random()*60)::int,
    trunc(random()*50, 2)              -- часы
FROM generate_series(1,250) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO task_comments (task_id, author_id, body)
SELECT 
    t.id,
    (SELECT id FROM users ORDER BY random() LIMIT 1),
    format(
        'Обсуждение задачи: %s. Нужно доработать %s', 
        substring(md5(random()::text) FROM 1 FOR 20),
        (ARRAY['валидацию','стили','логику','тесты'])[1+trunc(random()*3)::int]
    )
FROM tasks t
CROSS JOIN LATERAL generate_series(1, 4) s(i);
ON CONFLICT DO NOTHING;