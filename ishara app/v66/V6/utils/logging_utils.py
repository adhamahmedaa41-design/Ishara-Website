import logging
from pathlib import Path
from typing import Optional


def setup_logging(log_dir: Path, name: str = "asl_v6") -> logging.Logger:
    """
    Configure a module-level logger with console + file handlers.
    Safe to call multiple times; handlers are only added once.
    """
    log_dir.mkdir(parents=True, exist_ok=True)
    log_path = log_dir / f"{name}.log"

    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)

    if not logger.handlers:
        # Console handler
        ch = logging.StreamHandler()
        ch.setLevel(logging.INFO)
        ch_formatter = logging.Formatter(
            "[%(asctime)s] [%(levelname)s] %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
        ch.setFormatter(ch_formatter)
        logger.addHandler(ch)

        # File handler
        fh = logging.FileHandler(str(log_path), encoding="utf-8")
        fh.setLevel(logging.INFO)
        fh_formatter = logging.Formatter(
            "[%(asctime)s] [%(levelname)s] %(name)s - %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
        fh.setFormatter(fh_formatter)
        logger.addHandler(fh)

    return logger


def get_logger(name: Optional[str] = None) -> logging.Logger:
    """
    Convenience wrapper around logging.getLogger.
    Assumes setup_logging has been called at least once.
    """
    return logging.getLogger(name or "asl_v6")

