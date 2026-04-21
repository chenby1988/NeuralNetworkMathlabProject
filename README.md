# NN Simulation Pro v2.0 - Commercial-Grade Neural Network System

A production-ready neural network simulation and analysis platform built in MATLAB.

## Architecture

```
NN_Simulation_Pro/
├── config/              # Configuration management (JSON-based)
├── core/                # Infrastructure (Logger, Config, Exception, Audit)
├── data/                # Data pipeline (ETL, Validation, Cleaning, Versioning)
├── models/              # Model management (Versioning, Experiments, Hyperparam tuning)
├── training/            # Advanced training (Checkpointing, Early stopping, LR scheduling)
├── evaluation/          # Evaluation suite (Metrics, Cross-validation, Robustness, A/B)
├── gui/                 # Visualization dashboard
├── reports/             # Automated report generation
├── deployment/          # Model serving API, inference optimization, monitoring
├── security/            # Encryption, access control, audit trails
├── tests/               # Unit test suite
├── logs/                # Runtime logs
├── artifacts/           # Models, data versions, checkpoints
└── main.m               # System entry point
```

## Quick Start

1. Open MATLAB and navigate to project folder
2. In Command Window, type: `main`
3. Check `logs/` for execution logs and `reports/` for PDF output

## Key Features

| Module | Feature | File |
|--------|---------|------|
| Config | Centralized JSON config with dot-notation access | `core/ConfigManager.m` |
| Logging | 5-level logging (DEBUG to CRITICAL) with file rotation | `core/Logger.m` |
| Audit | Full compliance audit trail | `core/AuditLogger.m` |
| Data | Multi-source ETL with validation, cleaning, versioning | `data/data_pipeline.m` |
| Training | Checkpoint resume, early stopping, LR scheduling | `training/trainer.m` |
| HPO | Bayesian / Grid / Random hyperparameter search | `models/hyperparam_tuner.m` |
| Evaluation | 8+ metrics, K-Fold CV, robustness testing, A/B testing | `evaluation/` |
| GUI | Real-time training dashboard with 6 live plots | `gui/dashboard.m` |
| Reports | Auto-generated PDF reports with figures | `reports/report_generator.m` |
| Deployment | Model API wrapper, inference benchmark, monitoring | `deployment/` |
| Security | File encryption, RBAC access control | `security/` |

## Running Tests

```matlab
run_tests          % Run all tests
run_tests('core')  % Run core module tests only
```

## Customization

Edit `config/system_config.json` to change:
- Network architecture (`model.hidden_layers`)
- Training parameters (`model.training`)
- Data sources (`data.sources`)
- Evaluation settings (`evaluation`)

No code changes required.
