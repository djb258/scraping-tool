
-- Default troubleshooting entries (automatically loaded)
INSERT INTO shq.orbt_troubleshooting_guide (
    lookup_key, unique_id_pattern, process_id, error_code, error_type,
    error_title, error_description, business_impact, urgency_level,
    immediate_action, diagnostic_steps, resolution_steps, escalation_criteria,
    common_causes, prevention_tips, affected_agents, affected_domains, system_components,
    auto_resolvable, success_rate, avg_resolution_time_minutes
) VALUES 
(
    'ProcessData:CONN_TIMEOUT',
    '*.03.*.DB.*.*',
    'ProcessData',
    'CONN_TIMEOUT',
    'connection',
    'Database Connection Timeout',
    'Cannot connect to database within timeout period',
    'Data operations blocked, users cannot access features',
    'HIGH',
    'Retry connection, check database status endpoint',
    ARRAY['ping database_host', 'SELECT 1 FROM pg_stat_activity', 'Check connection pool'],
    ARRAY['Restart connection pool', 'Scale database if CPU > 80%', 'Clear pool if > 90% utilized'],
    'If 3 retries fail OR database unresponsive OR >100 affected users',
    ARRAY['Database overload', 'Connection pool exhaustion', 'Network issues'],
    ARRAY['Monitor pool utilization', 'Set up auto-scaling', 'Implement circuit breaker'],
    ARRAY['database-specialist', 'data-orchestrator'],
    ARRAY['data', 'platform'],
    ARRAY['PostgreSQL', 'Connection Pool', 'Neon Database'],
    true, 85.0, 5
),
(
    'ProcessPayment:PAY_DECLINED',
    '*.04.*.PAY.*.*',
    'ProcessPayment',
    'PAY_DECLINED',
    'payment',
    'Payment Card Declined',
    'Customer payment declined by payment processor',
    'Customer cannot complete purchase, revenue loss',
    'MEDIUM',
    'Check decline reason, show user-friendly message',
    ARRAY['Check Stripe dashboard', 'Verify card format', 'Check fraud flags'],
    ARRAY['Show decline message', 'Suggest alternative payment', 'Retry with 3D Secure'],
    'If >10 declines in 5 minutes OR working card declined',
    ARRAY['Insufficient funds', 'Expired card', 'Fraud detection'],
    ARRAY['Pre-validate cards', 'Implement retry logic', 'Use address verification'],
    ARRAY['payment-specialist', 'payment-orchestrator'],
    ARRAY['payment'],
    ARRAY['Stripe API', 'Payment Gateway'],
    true, 95.0, 2
) ON CONFLICT (lookup_key) DO NOTHING;
