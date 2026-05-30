from typing import Tuple

from tensorflow.keras import Sequential
from tensorflow.keras.layers import (
    LSTM,
    BatchNormalization,
    Dropout,
    Dense,
    Input,
)
from tensorflow.keras.regularizers import l2


def build_lstm_model(
    input_shape: Tuple[int, int],
    num_classes: int,
) -> Sequential:
    """
    Balanced LSTM architecture for sequence classification.

    - Two LSTM layers with dropout + batch norm
    - Two dense layers with dropout + light L2
    - Softmax output for multi-class classification
    """
    model = Sequential()
    model.add(Input(shape=input_shape))

    dense_reg = l2(0.0005)

    # First LSTM block
    model.add(
        LSTM(
            128,
            return_sequences=True,
            activation="tanh",
            dropout=0.2,
            recurrent_dropout=0.2,
        )
    )
    model.add(BatchNormalization())

    # Second LSTM block
    model.add(
        LSTM(
            256,
            return_sequences=False,
            activation="tanh",
            dropout=0.3,
            recurrent_dropout=0.3,
        )
    )
    model.add(BatchNormalization())

    # Dense blocks
    model.add(Dense(256, activation="relu", kernel_regularizer=dense_reg))
    model.add(Dropout(0.4))
    model.add(BatchNormalization())

    model.add(Dense(128, activation="relu", kernel_regularizer=dense_reg))
    model.add(Dropout(0.3))
    model.add(BatchNormalization())

    # Output
    model.add(Dense(num_classes, activation="softmax"))

    return model

