from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class PathsConfig:
    """
    Centralized project paths.

    base_dir: root for persistent data and models on D: drive.
    project_root: root for this V6 code.
    """

    # Root directory for datasets, models and logs (shared with earlier versions)
    base_dir: Path = Path("D:/Arabic_Sign_Language")

    # Root directory of this V6 project code
    project_root: Path = Path(__file__).resolve().parent

    @property
    def data_dir(self) -> Path:
        # Where MediaPipe keypoint sequences live
        return self.base_dir / "MP_Data_Custom"

    @property
    def models_dir(self) -> Path:
        return self.base_dir / "models_v6"

    @property
    def logs_dir(self) -> Path:
        return self.base_dir / "logs_v6"

    @property
    def evaluation_dir(self) -> Path:
        return self.base_dir / "evaluation_v6"


@dataclass
class TrainingConfig:
    """Hyperparameters and training-related settings."""

    sequence_length: int = 30
    test_size: float = 0.2
    random_state: int = 42
    epochs: int = 500
    batch_size: int = 16
    learning_rate: float = 3e-4
    early_stopping_patience: int = 50
    reduce_lr_patience: int = 20
    reduce_lr_factor: float = 0.5
    min_delta: float = 1e-4  # for EarlyStopping


@dataclass
class InferenceConfig:
    """Settings for real-time detection and smoothing."""

    # Temporal buffer size for smoothing predictions
    smoothing_window: int = 10
    # Minimum confidence required to accept a prediction
    confidence_threshold: float = 0.80
    # Cooldown (seconds) between adding new words to the sentence
    prediction_cooldown: float = 1.0


@dataclass
class CaptureConfig:
    """Settings for camera-based data capture."""

    sequence_length: int = 30
    min_hands_required: int = 1  # require at least one hand for a frame to be valid
    countdown_seconds: int = 3
    # Maximum retries for a sequence if quality checks fail
    max_retries_per_sequence: int = 3


@dataclass
class Config:
    """Top-level configuration object passed around the system."""

    # Use default_factory to avoid mutable-default issues with dataclasses
    paths: PathsConfig = field(default_factory=PathsConfig)
    training: TrainingConfig = field(default_factory=TrainingConfig)
    inference: InferenceConfig = field(default_factory=InferenceConfig)
    capture: CaptureConfig = field(default_factory=CaptureConfig)


def get_default_config() -> Config:
    """
    Convenience factory for creating a fully-populated Config instance.
    """
    cfg = Config()

    # Ensure important directories exist
    cfg.paths.base_dir.mkdir(parents=True, exist_ok=True)
    cfg.paths.data_dir.mkdir(parents=True, exist_ok=True)
    cfg.paths.models_dir.mkdir(parents=True, exist_ok=True)
    cfg.paths.logs_dir.mkdir(parents=True, exist_ok=True)
    cfg.paths.evaluation_dir.mkdir(parents=True, exist_ok=True)

    return cfg

