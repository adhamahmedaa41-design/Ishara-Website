from typing import Tuple

import cv2
import mediapipe as mp
import numpy as np


# Updated for MediaPipe 0.10+ API
BaseOptions = mp.tasks.BaseOptions
HolisticLandmarker = mp.tasks.vision.HolisticLandmarker
HolisticLandmarkerOptions = mp.tasks.vision.HolisticLandmarkerOptions
VisionRunningMode = mp.tasks.vision.RunningMode

mp_drawing = mp.tasks.vision.drawing_utils
mp_drawing_styles = mp.tasks.vision.drawing_styles


def create_holistic_landmarker(
    min_detection_confidence: float = 0.6,
    min_tracking_confidence: float = 0.6,
    model_complexity: int = 1,
) -> HolisticLandmarker:
    """
    Create a HolisticLandmarker instance with the new MediaPipe API.
    """
    # For MediaPipe 0.10+, we need to use the task-based API with the model file
    options = HolisticLandmarkerOptions(
        base_options=BaseOptions(model_asset_path="holistic_landmarker.task"),
        min_face_landmarks_confidence=min_detection_confidence,
        min_pose_landmarks_confidence=min_detection_confidence,
        min_hand_landmarks_confidence=min_detection_confidence,
        running_mode=VisionRunningMode.IMAGE,
    )
    return HolisticLandmarker.create_from_options(options)


def mediapipe_detection(
    image: np.ndarray, landmarker: HolisticLandmarker
) -> Tuple[np.ndarray, object]:
    """
    Run MediaPipe Holistic on a BGR image and return (image_bgr, results).
    Updated for MediaPipe 0.10+ API.
    """
    # Convert to MediaPipe Image format
    img_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=img_rgb)
    
    # Process the image
    results = landmarker.detect(mp_image)
    
    return image, results


def draw_styled_landmarks(image: np.ndarray, results: object) -> None:
    """
    Draw pose, face, and hand landmarks with consistent styling.
    Updated for MediaPipe 0.10+ API.
    """
    # For the new API, we need to pass the actual connection lists, not the class
    if results.pose_landmarks:
        mp_drawing.draw_landmarks(
            image,
            results.pose_landmarks,
            connections=mp.tasks.vision.PoseLandmarksConnections.POSE_LANDMARKS,
            landmark_drawing_spec=mp_drawing.DrawingSpec(color=(80, 22, 10), thickness=2, circle_radius=3),
            connection_drawing_spec=mp_drawing.DrawingSpec(color=(80, 44, 121), thickness=2, circle_radius=2),
        )

    if results.face_landmarks:
        mp_drawing.draw_landmarks(
            image,
            results.face_landmarks,
            connections=mp.tasks.vision.FaceLandmarksConnections.FACE_LANDMARKS_TESSELATION,
            landmark_drawing_spec=None,
            connection_drawing_spec=mp_drawing_styles.get_default_face_mesh_tesselation_style(),
        )

    if results.left_hand_landmarks:
        mp_drawing.draw_landmarks(
            image,
            results.left_hand_landmarks,
            connections=mp.tasks.vision.HandLandmarksConnections.HAND_CONNECTIONS,
            landmark_drawing_spec=mp_drawing.DrawingSpec(color=(121, 22, 76), thickness=3, circle_radius=4),
            connection_drawing_spec=mp_drawing.DrawingSpec(color=(121, 44, 250), thickness=3, circle_radius=2),
        )

    if results.right_hand_landmarks:
        mp_drawing.draw_landmarks(
            image,
            results.right_hand_landmarks,
            connections=mp.tasks.vision.HandLandmarksConnections.HAND_CONNECTIONS,
            landmark_drawing_spec=mp_drawing.DrawingSpec(color=(245, 117, 66), thickness=3, circle_radius=4),
            connection_drawing_spec=mp_drawing.DrawingSpec(color=(245, 66, 230), thickness=3, circle_radius=2),
        )


def extract_keypoints(results: object) -> np.ndarray:
    """
    Extract pose, face, left-hand and right-hand landmarks into a flat feature vector.
    Shape: (1692,) matching the existing system.
    Updated for MediaPipe 0.10+ API.
    """
    # In the new API, landmarks are accessed as lists of landmark objects
    pose = (
        np.array(
            [
                [landmark.x, landmark.y, landmark.z, landmark.visibility]
                for landmark in results.pose_landmarks
            ]
        ).flatten()
        if results.pose_landmarks
        else np.zeros(33 * 4)
    )
    face = (
        np.array([[landmark.x, landmark.y, landmark.z] for landmark in results.face_landmarks]).flatten()
        if results.face_landmarks
        else np.zeros(478 * 3)
    )
    lh = (
        np.array([[landmark.x, landmark.y, landmark.z] for landmark in results.left_hand_landmarks]).flatten()
        if results.left_hand_landmarks
        else np.zeros(21 * 3)
    )
    rh = (
        np.array([[landmark.x, landmark.y, landmark.z] for landmark in results.right_hand_landmarks]).flatten()
        if results.right_hand_landmarks
        else np.zeros(21 * 3)
    )
    return np.concatenate([pose, face, lh, rh])

