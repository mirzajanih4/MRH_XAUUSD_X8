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

        stop_scaled = stop_ratio / (stop_ratio + 0.0005)

        return [permission, stop_scaled]

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


    # STEP137.10.3A - In-memory model rollback foundation
    def snapshot_state(self):
        return (
            tuple(self.weights),
            self.bias,
            self.trained_samples,
        )

    def restore_state(self, state):
        try:
            weights, bias, count = state

            if (
                len(weights) != 2
                or not all(isfinite(float(w)) for w in weights)
                or not isfinite(float(bias))
                or type(count) is not int
                or count < 0
            ):
                raise ValueError

            restored_weights = [float(w) for w in weights]
            restored_bias = float(bias)

        except (TypeError, ValueError, OverflowError):
            raise ValueError("INVALID_MODEL_STATE")

        self.weights = restored_weights
        self.bias = restored_bias
        self.trained_samples = count

    # STEP137.11.1 - Account-scoped model checkpoint
    @staticmethod
    def _validate_account_scope(scope):
        parts = scope.split("|") if isinstance(scope, str) else []

        if (
            len(parts) != 4
            or not all(parts)
            or not parts[1].isdigit()
            or not parts[2].isdigit()
        ):
            raise ValueError("INVALID_ACCOUNT_SCOPE")

    # STEP137.10.3B - Persistent model checkpoint
    def save_checkpoint(self, file_path, account_scope):
        import hashlib
        import json
        import os
        import tempfile
        from pathlib import Path

        self._validate_account_scope(account_scope)

        path = Path(file_path)
        payload = {
            "version": 4,
            "account_scope": account_scope,
            "state": self.snapshot_state(),
        }

        canonical = json.dumps(
            payload,
            sort_keys=True,
            separators=(",", ":"),
            allow_nan=False,
        )

        record = {
            **payload,
            "sha256": hashlib.sha256(
                canonical.encode("utf-8")
            ).hexdigest(),
        }

        temp_path = None

        try:
            with tempfile.NamedTemporaryFile(
                mode="w",
                encoding="utf-8",
                dir=path.parent,
                prefix=path.name + ".",
                suffix=".tmp",
                delete=False,
            ) as file:
                temp_path = Path(file.name)
                json.dump(record, file, allow_nan=False)
                file.flush()
                os.fsync(file.fileno())

            os.replace(temp_path, path)

        finally:
            if temp_path is not None:
                temp_path.unlink(missing_ok=True)

    @classmethod
    def load_checkpoint(cls, file_path, expected_account_scope):
        import hashlib
        import json
        from pathlib import Path

        try:
            cls._validate_account_scope(expected_account_scope)

            record = json.loads(
                Path(file_path).read_text(encoding="utf-8")
            )

            if (
                type(record) is not dict
                or set(record) != {"version", "account_scope", "state", "sha256"}
                or type(record["version"]) is not int
                or record["version"] != 4
                or type(record["account_scope"]) is not str
                or record["account_scope"] != expected_account_scope
                or type(record["sha256"]) is not str
            ):
                raise ValueError

            payload = {
                "version": record["version"],
                "account_scope": record["account_scope"],
                "state": record["state"],
            }

            canonical = json.dumps(
                payload,
                sort_keys=True,
                separators=(",", ":"),
                allow_nan=False,
            )

            expected_hash = hashlib.sha256(
                canonical.encode("utf-8")
            ).hexdigest()

            if expected_hash != record["sha256"]:
                raise ValueError

            model = cls()
            model.restore_state(record["state"])
            return model

        except (
            OSError,
            ValueError,
            TypeError,
            KeyError,
            OverflowError,
        ) as error:
            raise ValueError(
                "INVALID_MODEL_CHECKPOINT"
            ) from error


    # STEP137.10.3 - Controlled model update with rollback
    def try_learn_with_validation(
        self, features, label, validation_samples
    ):
        if not validation_samples:
            raise ValueError("EMPTY_VALIDATION")

        previous_state = self.snapshot_state()

        try:
            def validation_error():
                errors = []

                for sample_features, actual_label in validation_samples:
                    if type(actual_label) is not int or actual_label not in (0, 1):
                        raise ValueError("INVALID_VALIDATION_LABEL")

                    prediction = self.predict_probability(sample_features)
                    errors.append((prediction - actual_label) ** 2)

                return sum(errors) / len(errors)

            before = validation_error()

            self.learn_one(features, label)

            after = validation_error()

            if not isfinite(after) or after >= before:
                self.restore_state(previous_state)
                return False

            return True

        except Exception:
            self.restore_state(previous_state)
            raise



# STEP137.10.2F - Offline walk-forward model evaluation
def evaluate_walk_forward(
    plan, features, outcomes, model_factory=EntryQualityModel
):
    results = []

    for test_id, training_ids in plan:
        model = model_factory()

        for train_id in training_ids:
            pnl = outcomes[train_id][1]

            if pnl == 0:
                continue

            label = int(pnl > 0)
            model.learn_one(features[train_id], label)

        if model.trained_samples == 0:
            continue

        # Predict before reading the test outcome
        probability = model.predict_probability(features[test_id])

        test_pnl = outcomes[test_id][1]

        if test_pnl == 0:
            continue

        results.append({
            "test_id": test_id,
            "trained_samples": model.trained_samples,
            "probability": probability,
            "actual_label": int(test_pnl > 0),
        })

    return results
