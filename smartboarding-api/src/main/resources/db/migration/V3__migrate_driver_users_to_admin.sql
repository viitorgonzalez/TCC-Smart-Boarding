-- Reforma 2026-08-14: papel DRIVER removido do dominio (docs/spec.md RN23).
-- Motorista e adm mesmo -- os dois usuarios seed com role='DRIVER' (V2) viram ADMIN de fato,
-- mantendo login/senha/historico.
UPDATE users SET role = 'ADMIN' WHERE role = 'DRIVER';
