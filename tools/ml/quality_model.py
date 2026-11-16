
# STEP137.10.1G - Lightweight incremental ML foundation

from math import exp, isfinite


class EntryQualityModel:
    def __init__(self):
        self.weights = [0.0, 0.0]
        self.bias = 0.0
        self.trained_samples = 0

    def _features(self, features):
        permission = float(features["permission_scaled"])
        stop_ratio = float(features["stop_distance_ratio"])

        if (
            not isfinite(permission)
            or not isfinite(stop_ratio)
            or not 0.0 < permission <= 1.0
            or not 0.0 < stop_ratio < 1.0
        ):
            raise ValueError("Invalid ML features")

        return [permission, stop_ratio]

    def _probability(self, values):
        score = self.bias + sum(
            weight * value
            for weight, value in zip(self.weights, values)
        )

        if score >= 0:
            return 1.0 / (1.0 + exp(-score))

        z = exp(score)
        return z / (1.0 + z)

    def predict_probability(self, features):
        if self.trained_samples == 0:
            raise RuntimeError("MODEL_NOT_TRAINED")

        return self._probability(self._features(features))

    def learn_one(self, features, label, learning_rate=0.01):
        if label not in (0, 1):
            raise ValueError("Invalid outcome label")

        if not 0.0 < learning_rate <= 1.0:
            raise ValueError("Invalid learning rate")

        values = self._features(features)
        prediction = self._probability(values)
        error = label - prediction

        for i in range(len(self.weights)):
            self.weights[i] += learning_rate * error * values[i]

        self.bias += learning_rate * error
        self.trained_samples += 1
