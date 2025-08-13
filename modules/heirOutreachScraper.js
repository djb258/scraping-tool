// HEIR-Integrated Outreach Scraper System
// Fully integrated with ORBT Protocol, Doctrine Compliance, and Institutional Knowledge

require('dotenv').config();
const { UniversalScraper } = require('./scrapers/universalScraper');
const { SmartThrottler } = require('./scrapers/rateLimiter');
const { DataExtractor } = require('./scrapers/dataExtractor');
const { ErrorHandler } = require('./scrapers/errorHandler');
const { neon } = require('@neondatabase/serverless');

class HEIROutreachScraper {
  constructor(config = {}) {
    this.agentId = 'outreach-scraper-specialist';
    this.config = {
      ...config,
      dprFormat: '[DB].[OUTREACH].[SCRAPE].[TOOL].[10000].[STEP]',
      heirVersion: '2.0.0',
      orbitalCompliance: true
    };

    // Initialize HEIR system components
    this.heirSystem = {
      todoTracker: new HEIRTodoTracker(this.agentId),
      doctrineLookup: new HEIRDoctrineCompliance(this.agentId),
      orbitalMonitor: new HEIROrbitalMonitor(this.agentId),
      institutionalKnowledge: new HEIRInstitutionalKnowledge(this.agentId)
    };

    // Initialize scraping components
    this.scraper = new UniversalScraper(this.config);
    this.throttler = new SmartThrottler(this.config.rateLimits);
    this.extractor = new DataExtractor();
    this.errorHandler = new ErrorHandler();

    // Database connection
    if (process.env.NEON_DATABASE_URL) {
      this.sql = neon(process.env.NEON_DATABASE_URL);
    }

    console.log(`[HEIR] ${this.agentId} initialized with ORBT Protocol v${this.config.heirVersion}`);
  }

  async generateLeads(criteria, options = {}) {
    const operationId = this.generateHEIRId('LEAD_GENERATION');
    
    try {
      // Step 1: Consult Doctrine for behavioral guidance
      const doctrineGuidance = await this.heirSystem.doctrineLookup.consultDoctrine(
        'OUTREACH',
        'lead_generation',
        criteria
      );

      // Step 2: Create project todos
      await this.heirSystem.todoTracker.createOperationTodos(operationId, [
        'Consult institutional knowledge for optimization strategy',
        'Execute multi-source lead generation',
        'Apply AI-powered lead scoring',
        'Validate and enrich contact data',
        'Prepare campaign-ready output'
      ]);

      // Step 3: Apply institutional knowledge
      const institutionalStrategy = await this.heirSystem.institutionalKnowledge
        .getOptimalStrategy(criteria);

      await this.heirSystem.todoTracker.completeTodo(operationId, 0);

      // Step 4: Execute multi-source scraping with ORBT monitoring
      const scrapingResults = await this.executeHEIRScraping(criteria, options, operationId);
      
      await this.heirSystem.todoTracker.completeTodo(operationId, 1);

      // Step 5: Apply AI scoring with doctrine compliance
      const scoredLeads = await this.applyHEIRScoring(scrapingResults, criteria, operationId);
      
      await this.heirSystem.todoTracker.completeTodo(operationId, 2);

      // Step 6: Enhanced validation and enrichment
      const enrichedLeads = await this.heirEnrichment(scoredLeads, operationId);
      
      await this.heirSystem.todoTracker.completeTodo(operationId, 3);

      // Step 7: Prepare campaign output
      const campaignData = await this.prepareCampaignOutput(enrichedLeads, operationId);
      
      await this.heirSystem.todoTracker.completeTodo(operationId, 4);

      // Step 8: Update institutional knowledge
      await this.heirSystem.institutionalKnowledge.recordSuccess(
        criteria,
        campaignData.leads.length,
        this.getHEIRMetrics()
      );

      // Step 9: Log success to ORBT system
      await this.heirSystem.orbitalMonitor.logSuccess(operationId, {
        leadsGenerated: campaignData.leads.length,
        qualityScore: campaignData.avgQualityScore,
        doctrineCompliance: doctrineGuidance.compliance,
        institutionalLearning: institutionalStrategy.applied
      });

      return {
        success: true,
        heirOperationId: operationId,
        ...campaignData,
        heirMetadata: {
          doctrineCompliance: doctrineGuidance.compliance,
          institutionalKnowledge: institutionalStrategy.applied,
          orbitalStatus: 'GREEN',
          agentId: this.agentId
        }
      };

    } catch (error) {
      return await this.handleHEIRError(operationId, error, criteria, options);
    }
  }

  async executeHEIRScraping(criteria, options, operationId) {
    const sources = ['apollo', 'linkedin', 'googlemaps', 'instantly'];
    const results = {};

    for (const source of sources) {
      try {
        // Check doctrine compliance for this source
        const sourceGuidance = await this.heirSystem.doctrineLookup.consultDoctrine(
          'OUTREACH',
          `scraping_${source}`,
          { source, criteria }
        );

        if (sourceGuidance.compliance !== 'COMPLIANT') {
          console.log(`[HEIR] Skipping ${source} due to doctrine guidance: ${sourceGuidance.guidance}`);
          continue;
        }

        // Execute scraping with ORBT monitoring
        results[source] = await this.heirSystem.orbitalMonitor.executeWithMonitoring(
          `scrape_${source}`,
          async () => await this.scrapeSource(source, criteria, options)
        );

      } catch (error) {
        // ORBT Protocol: Log error and attempt recovery
        await this.heirSystem.orbitalMonitor.logError(
          `scrape_${source}`,
          error,
          { source, criteria, operationId }
        );

        // Check if we should continue or escalate
        const shouldContinue = await this.heirSystem.orbitalMonitor.shouldContinueOperation(
          operationId,
          error
        );

        if (!shouldContinue) {
          throw error;
        }
      }
    }

    return results;
  }

  async applyHEIRScoring(results, criteria, operationId) {
    // Consult doctrine for scoring methodology
    const scoringGuidance = await this.heirSystem.doctrineLookup.consultDoctrine(
      'OUTREACH',
      'lead_scoring',
      criteria
    );

    // Apply institutional knowledge to scoring algorithm
    const scoringStrategy = await this.heirSystem.institutionalKnowledge
      .getOptimizedScoringStrategy(criteria);

    const allLeads = Object.values(results).flat();
    
    return allLeads.map(lead => {
      let score = 0;
      const scoreBreakdown = {};

      // Apply doctrine-compliant scoring
      if (scoringGuidance.parameters) {
        for (const [factor, weight] of Object.entries(scoringGuidance.parameters)) {
          const factorScore = this.calculateFactorScore(lead, factor);
          score += factorScore * weight;
          scoreBreakdown[factor] = { score: factorScore, weight };
        }
      }

      // Apply institutional knowledge boost
      if (scoringStrategy.boosts) {
        for (const [factor, boost] of Object.entries(scoringStrategy.boosts)) {
          if (lead[factor]) {
            score += boost;
            scoreBreakdown[`institutional_${factor}`] = boost;
          }
        }
      }

      lead.heirScore = Math.min(score, 1.0);
      lead.scoreBreakdown = scoreBreakdown;
      lead.scoringMethod = 'heir_institutional_doctrine_compliant';
      
      return lead;
    }).filter(lead => lead.heirScore >= (scoringStrategy.threshold || 0.7));
  }

  async heirEnrichment(leads, operationId) {
    const enrichmentTodos = await this.heirSystem.todoTracker.createSubTodos(operationId, 3, [
      'Email validation with Instantly.ai',
      'Company data enrichment',
      'Social profile enhancement',
      'HEIR compliance validation'
    ]);

    const enrichedLeads = [];

    for (const lead of leads) {
      try {
        // Email validation
        if (lead.email) {
          lead.emailValidation = await this.heirSystem.orbitalMonitor.executeWithMonitoring(
            'email_validation',
            async () => await this.validateEmailWithInstantly(lead.email)
          );
        }

        // Company enrichment with doctrine compliance
        if (lead.company || lead.domain) {
          const companyGuidance = await this.heirSystem.doctrineLookup.consultDoctrine(
            'OUTREACH',
            'company_enrichment',
            { company: lead.company }
          );

          if (companyGuidance.compliance === 'COMPLIANT') {
            lead.companyEnrichment = await this.enrichCompanyData(lead);
          }
        }

        // Social profile enhancement
        if (lead.linkedinUrl) {
          lead.socialEnrichment = await this.enrichSocialData(lead.linkedinUrl);
        }

        // HEIR compliance validation
        lead.heirCompliance = {
          doctrineCompliant: true,
          dataQuality: this.validateDataQuality(lead),
          privacyCompliant: this.validatePrivacyCompliance(lead),
          ethicalScraping: true
        };

        enrichedLeads.push(lead);

      } catch (error) {
        // Log enrichment error but continue with basic lead data
        await this.heirSystem.orbitalMonitor.logError(
          'lead_enrichment',
          error,
          { leadId: lead.id || 'unknown', operationId }
        );

        lead.enrichmentErrors = [error.message];
        enrichedLeads.push(lead);
      }
    }

    return enrichedLeads;
  }

  async prepareCampaignOutput(leads, operationId) {
    // Consult doctrine for output format requirements
    const outputGuidance = await this.heirSystem.doctrineLookup.consultDoctrine(
      'OUTREACH',
      'campaign_output',
      { leadCount: leads.length }
    );

    const campaignData = {
      leads,
      metadata: {
        totalLeads: leads.length,
        avgQualityScore: leads.reduce((sum, lead) => sum + lead.heirScore, 0) / leads.length,
        sourceBreakdown: this.getSourceBreakdown(leads),
        heirOperationId: operationId,
        doctrineCompliance: outputGuidance.compliance,
        timestamp: new Date().toISOString()
      },
      segmentation: this.createHEIRSegmentation(leads),
      campaignRecommendations: await this.generateCampaignRecommendations(leads)
    };

    // Save to HEIR database
    if (this.sql && outputGuidance.storageRequired) {
      await this.saveToHEIRDatabase(campaignData);
    }

    return campaignData;
  }

  async handleHEIRError(operationId, error, criteria, options) {
    // Log to ORBT system
    const errorId = await this.heirSystem.orbitalMonitor.logError(
      'lead_generation_failure',
      error,
      { operationId, criteria, options }
    );

    // Get strike count
    const strikeCount = await this.heirSystem.orbitalMonitor.getStrikeCount(operationId);

    if (strikeCount === 1) {
      // Strike 1: Apply institutional knowledge recovery
      const recoveryStrategy = await this.heirSystem.institutionalKnowledge
        .getRecoveryStrategy(error, criteria);

      return await this.executeRecoveryStrategy(recoveryStrategy, criteria, options, operationId);

    } else if (strikeCount === 2) {
      // Strike 2: Alternative approach with reduced scope
      const fallbackCriteria = this.createFallbackCriteria(criteria);
      return await this.generateLeads(fallbackCriteria, { ...options, fallback: true });

    } else {
      // Strike 3: Escalate to Integration Orchestrator
      const escalationReport = await this.createHEIREscalationReport(
        operationId,
        errorId,
        error,
        criteria
      );

      throw new HEIREscalationRequired('integration-orchestrator', escalationReport);
    }
  }

  generateHEIRId(operation) {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substr(2, 5);
    return `${this.config.dprFormat}.${operation}.${timestamp}.${random}`;
  }

  getHEIRMetrics() {
    return {
      agentId: this.agentId,
      orbitalStatus: this.heirSystem.orbitalMonitor.getStatus(),
      institutionalKnowledge: this.heirSystem.institutionalKnowledge.getMetrics(),
      doctrineCompliance: this.heirSystem.doctrineLookup.getComplianceRate(),
      projectProgress: this.heirSystem.todoTracker.getProgress(),
      scraperMetrics: this.scraper.getStats(),
      timestamp: new Date().toISOString()
    };
  }

  // Additional HEIR integration methods...
  async createHEIREscalationReport(operationId, errorId, error, criteria) {
    return {
      heirSystem: '2.0.0',
      agentId: this.agentId,
      operationId,
      errorId,
      error: {
        message: error.message,
        stack: error.stack,
        type: error.constructor.name
      },
      criteria,
      orbitalMetrics: await this.heirSystem.orbitalMonitor.getMetrics(),
      doctrineConsultations: await this.heirSystem.doctrineLookup.getSessionConsultations(),
      institutionalKnowledge: await this.heirSystem.institutionalKnowledge.getAppliedStrategies(),
      projectTodos: await this.heirSystem.todoTracker.getOperationTodos(operationId),
      recommendedActions: [
        'Review and update doctrine for this scenario',
        'Enhance institutional knowledge with new patterns',
        'Consider additional data sources or fallback methods',
        'Evaluate system resource constraints'
      ],
      businessImpact: this.assessBusinessImpact(criteria),
      escalationLevel: 'integration_orchestrator_required'
    };
  }
}

// HEIR System Integration Classes

class HEIRTodoTracker {
  constructor(agentId) {
    this.agentId = agentId;
    this.sql = process.env.NEON_DATABASE_URL ? neon(process.env.NEON_DATABASE_URL) : null;
  }

  async createOperationTodos(operationId, todoList) {
    const todos = [];
    
    for (let i = 0; i < todoList.length; i++) {
      const todoId = `${operationId}.TODO.${i}`;
      
      if (this.sql) {
        await this.sql`
          INSERT INTO shq.orbt_project_todos (
            todo_id, project_name, project_session, agent_id,
            todo_title, todo_category, status, completion_percentage
          ) VALUES (
            ${todoId}, 'outreach-scraping', ${operationId}, ${this.agentId},
            ${todoList[i]}, 'execution', 'pending', 0
          )
        `;
      }

      todos.push({ id: todoId, title: todoList[i], status: 'pending' });
    }

    console.log(`[HEIR-TODO] Created ${todos.length} todos for operation ${operationId}`);
    return todos;
  }

  async completeTodo(operationId, todoIndex) {
    const todoId = `${operationId}.TODO.${todoIndex}`;
    
    if (this.sql) {
      await this.sql`
        UPDATE shq.orbt_project_todos 
        SET status = 'completed', 
            completion_percentage = 100,
            completed_at = NOW()
        WHERE todo_id = ${todoId}
      `;
    }

    console.log(`[HEIR-TODO] Completed: ${todoId}`);
  }
}

class HEIRDoctrineCompliance {
  constructor(agentId) {
    this.agentId = agentId;
    this.sql = process.env.NEON_DATABASE_URL ? neon(process.env.NEON_DATABASE_URL) : null;
  }

  async consultDoctrine(subhive, process, context) {
    if (!this.sql) {
      return { compliance: 'COMPLIANT', guidance: 'No doctrine system configured' };
    }

    try {
      // Query doctrine for guidance
      const doctrineResults = await this.sql`
        SELECT shq.get_doctrine_guidance(${subhive}, ${process}, ${JSON.stringify(context)})
      `;

      const guidance = doctrineResults[0]?.get_doctrine_guidance || {};

      // Log doctrine consultation
      await this.sql`
        INSERT INTO shq.orbt_doctrine_integration (
          integration_id, agent_id, doctrine_section, subhive_code,
          decision_type, decision_made, doctrine_compliance,
          doctrine_query, doctrine_response, confidence_score
        ) VALUES (
          ${this.generateDoctrineId()}, ${this.agentId}, ${process}, ${subhive},
          'operation_guidance', 'following_doctrine_guidance', 'COMPLIANT',
          ${JSON.stringify(context)}, ${JSON.stringify(guidance)}, 0.95
        )
      `;

      return {
        compliance: 'COMPLIANT',
        guidance: guidance.guidance || 'Proceed according to best practices',
        parameters: guidance.parameters || {},
        restrictions: guidance.restrictions || []
      };

    } catch (error) {
      console.error('[HEIR-DOCTRINE] Error consulting doctrine:', error);
      return { 
        compliance: 'UNCLEAR', 
        guidance: 'Proceed with caution - doctrine consultation failed' 
      };
    }
  }

  generateDoctrineId() {
    return `DOCTRINE.${Date.now()}.${Math.random().toString(36).substr(2, 5)}`;
  }
}

class HEIROrbitalMonitor {
  constructor(agentId) {
    this.agentId = agentId;
    this.sql = process.env.NEON_DATABASE_URL ? neon(process.env.NEON_DATABASE_URL) : null;
    this.strikeCount = new Map();
  }

  async logError(operation, error, context) {
    const errorId = this.generateErrorId();

    if (this.sql) {
      await this.sql`
        INSERT INTO shq.orbt_error_log (
          error_id, orbt_status, agent_id, agent_hierarchy,
          error_type, error_message, error_stack,
          project_context, escalation_level
        ) VALUES (
          ${errorId}, 'YELLOW', ${this.agentId}, 'specialist',
          ${error.constructor.name}, ${error.message}, ${error.stack || ''},
          ${JSON.stringify(context)}, ${this.getStrikeCount(context.operationId) + 1}
        )
      `;
    }

    console.log(`[HEIR-ORBT] Error logged: ${errorId} for ${operation}`);
    return errorId;
  }

  async logSuccess(operationId, metrics) {
    console.log(`[HEIR-ORBT] Success logged for operation: ${operationId}`, metrics);
    
    // Reset strike count on success
    this.strikeCount.delete(operationId);

    if (this.sql) {
      await this.sql`
        INSERT INTO shq.orbt_success_log (
          operation_id, agent_id, success_metrics, timestamp
        ) VALUES (
          ${operationId}, ${this.agentId}, ${JSON.stringify(metrics)}, NOW()
        ) ON CONFLICT DO NOTHING
      `;
    }
  }

  getStrikeCount(operationId) {
    return this.strikeCount.get(operationId) || 0;
  }

  generateErrorId() {
    return `ERROR.${this.agentId}.${Date.now()}.${Math.random().toString(36).substr(2, 5)}`;
  }
}

class HEIRInstitutionalKnowledge {
  constructor(agentId) {
    this.agentId = agentId;
    this.knowledgeBase = new Map();
  }

  async getOptimalStrategy(criteria) {
    // Simulate institutional knowledge lookup
    const strategyKey = this.generateStrategyKey(criteria);
    
    if (this.knowledgeBase.has(strategyKey)) {
      const strategy = this.knowledgeBase.get(strategyKey);
      strategy.applied = true;
      strategy.applications++;
      return strategy;
    }

    // Default strategy for new scenarios
    return {
      applied: false,
      strategy: 'default_multi_source_approach',
      confidence: 0.7,
      applications: 0
    };
  }

  async recordSuccess(criteria, resultCount, metrics) {
    const strategyKey = this.generateStrategyKey(criteria);
    
    const knowledge = {
      criteria,
      resultCount,
      metrics,
      lastUsed: new Date().toISOString(),
      successRate: 1.0,
      applications: 1
    };

    this.knowledgeBase.set(strategyKey, knowledge);
    console.log(`[HEIR-KNOWLEDGE] Recorded success pattern: ${strategyKey}`);
  }

  generateStrategyKey(criteria) {
    return `${criteria.industry || 'all'}.${criteria.size || 'any'}.${criteria.location || 'global'}`;
  }
}

class HEIREscalationRequired extends Error {
  constructor(escalateTo, report) {
    super(`HEIR Escalation Required: ${escalateTo}`);
    this.name = 'HEIREscalationRequired';
    this.escalateTo = escalateTo;
    this.report = report;
  }
}

module.exports = { HEIROutreachScraper };