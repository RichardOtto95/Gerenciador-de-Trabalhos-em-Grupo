-- ========================================
-- PROCEDURE: SISTEMA DE NOTIFICAÇÕES INTELIGENTES
-- ========================================
CREATE OR REPLACE PROCEDURE gerar_notificacoes_inteligentes()
LANGUAGE plpgsql
AS $$
DECLARE
    v_contador INTEGER := 0;
    v_tarefa RECORD;
    v_usuario RECORD;
    v_dias_vencimento INTEGER;
    v_prioridade_alta INTEGER := 3;
    v_prioridade_urgente INTEGER := 4;
BEGIN
    -- Notificações para tarefas vencendo em 24h
    FOR v_tarefa IN 
        SELECT DISTINCT t.id, t.titulo, t.data_vencimento, t.prioridade, t.grupo_id
        FROM tarefas t
        INNER JOIN atribuicoes_tarefa at ON t.id = at.tarefa_id
        WHERE t.data_vencimento = CURRENT_DATE + INTERVAL '1 day'
        AND t.status_id != 4 -- Não concluída
        AND NOT EXISTS (
            SELECT 1 FROM notificacoes n 
            WHERE n.entidade_id = t.id
            AND n.tipo = 'tarefa_vencendo'
            AND n.data_criacao > CURRENT_TIMESTAMP - INTERVAL '12 hours'
        )
    LOOP
        -- Notificar todos os responsáveis
        FOR v_usuario IN 
            SELECT DISTINCT u.id, u.nome
            FROM usuarios u
            INNER JOIN atribuicoes_tarefa at ON u.id = at.usuario_id
            WHERE at.tarefa_id = v_tarefa.id AND at.ativo = true
        LOOP
            INSERT INTO notificacoes (
                id, usuario_id, tipo, titulo, mensagem, 
                entidade_tipo, entidade_id, lida, data_criacao
            ) VALUES (
                uuid_generate_v4(),
                v_usuario.id,
                'tarefa_vencendo',
                'Tarefa vence amanhã!',
                'A tarefa "' || v_tarefa.titulo || '" vence amanhã. Prioridade: ' || 
                CASE v_tarefa.prioridade 
                    WHEN 1 THEN 'Baixa'
                    WHEN 2 THEN 'Normal'
                    WHEN 3 THEN 'Alta'
                    WHEN 4 THEN 'Urgente'
                END,
                'tarefa',
                v_tarefa.id,
                false,
                CURRENT_TIMESTAMP
            );
            v_contador := v_contador + 1;
        END LOOP;
    END LOOP;
END;
$$;