import cv2

# Test camera access
cap = cv2.VideoCapture(0)
if cap.isOpened():
    print("✅ Camera opened successfully at index 0")
    ret, frame = cap.read()
    if ret:
        print("✅ Camera can capture frames")
    else:
        print("❌ Camera opened but cannot capture frames")
    cap.release()
else:
    print("❌ Cannot open camera at index 0")

# Try other indices
for idx in range(1, 5):
    cap = cv2.VideoCapture(idx)
    if cap.isOpened():
        print(f"✅ Camera opened at index {idx}")
        cap.release()
        break
    else:
        print(f"❌ Cannot open camera at index {idx}")
    cap.release()