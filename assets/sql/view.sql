-- ========================================
-- VIEW: RELATÓRIO DE PRODUTIVIDADE POR GRUPO (SIMPLIFICADA)
-- ========================================
-- View consolidada com métricas essenciais de produtividade por grupo

CREATE OR REPLACE VIEW vw_produtividade_grupo AS
WITH tarefas_stats AS (
    SELECT 
        t.grupo_id,
        COUNT(*) as total_tarefas,
        COUNT(CASE WHEN t.status_id = 4 THEN 1 END) as tarefas_concluidas,
        COUNT(CASE WHEN t.status_id = 2 THEN 1 END) as tarefas_em_andamento,
        COUNT(CASE WHEN t.status_id = 1 THEN 1 END) as tarefas_pendentes,
        COUNT(CASE WHEN t.data_vencimento < CURRENT_DATE AND t.status_id NOT IN (4, 5) THEN 1 END) as tarefas_atrasadas,
        AVG(t.progresso) as progresso_medio,
        SUM(t.horas_trabalhadas) as total_horas_trabalhadas
    FROM tarefas t
    GROUP BY t.grupo_id
),
membros_stats AS (
    SELECT 
        ug.grupo_id,
        COUNT(*) as total_membros,
        COUNT(CASE WHEN ug.ativo = true THEN 1 END) as membros_ativos
    FROM usuarios_grupos ug
    GROUP BY ug.grupo_id
),
atividade_stats AS (
    SELECT 
        a.grupo_id,
        COUNT(DISTINCT a.usuario_id) as usuarios_ativos_30dias
    FROM atividades a
    WHERE a.data_acao >= CURRENT_DATE - INTERVAL '30 days'
    AND a.grupo_id IS NOT NULL
    GROUP BY a.grupo_id
)
SELECT 
    g.id as grupo_id,
    g.nome as nome_grupo,
    g.descricao as descricao_grupo,
    u_criador.nome as nome_criador,
    COALESCE(ms.total_membros, 0) as total_membros,
    COALESCE(ms.membros_ativos, 0) as membros_ativos,
    COALESCE(ts.total_tarefas, 0) as total_tarefas,
    COALESCE(ts.tarefas_concluidas, 0) as tarefas_concluidas,
    COALESCE(ts.tarefas_em_andamento, 0) as tarefas_em_andamento,
    COALESCE(ts.tarefas_pendentes, 0) as tarefas_pendentes,
    COALESCE(ts.tarefas_atrasadas, 0) as tarefas_atrasadas,
    COALESCE(ts.progresso_medio, 0) as progresso_medio_geral,
    COALESCE(ts.total_horas_trabalhadas, 0) as total_horas_trabalhadas,
    COALESCE(act.usuarios_ativos_30dias, 0) as usuarios_ativos_30dias,
    CASE 
        WHEN COALESCE(ts.total_tarefas, 0) > 0 
        THEN ROUND((COALESCE(ts.tarefas_concluidas, 0)::DECIMAL / ts.total_tarefas) * 100, 2)
        ELSE 0 
    END as taxa_conclusao_percentual,
    CASE 
        WHEN COALESCE(ts.tarefas_atrasadas, 0) > COALESCE(ts.tarefas_concluidas, 0) THEN 'Crítico'
        WHEN COALESCE(ts.tarefas_atrasadas, 0) > 0 THEN 'Atenção'
        WHEN COALESCE(ts.progresso_medio, 0) > 50 THEN 'Bom'
        ELSE 'Regular'
    END as status_saude_grupo
FROM grupos g
LEFT JOIN usuarios u_criador ON g.criador_id = u_criador.id
LEFT JOIN tarefas_stats ts ON g.id = ts.grupo_id
LEFT JOIN membros_stats ms ON g.id = ms.grupo_id
LEFT JOIN atividade_stats act ON g.id = act.grupo_id;