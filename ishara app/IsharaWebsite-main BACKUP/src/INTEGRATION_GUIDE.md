# ISHARA Integration Guide

## 🎯 Quick Start

Welcome to the integrated ISHARA experience! This guide will help you navigate both the website and mobile app seamlessly.

## 🚀 First Launch

1. **Welcome Screen**: On your first visit, you'll see a welcome modal explaining the dual-mode system
2. **View Switcher**: A floating switcher appears at the top of the screen
3. **Auto-Hide**: The switcher automatically hides after 5 seconds (hover top area to reveal)

## 🔄 Switching Between Views

### **Website Mode** (Default)
- Full desktop cinematic experience
- Scroll-based navigation through sections
- Advanced animations and particle effects
- Interactive demos and simulations

**To Access:**
- Click the "Website" button in the switcher
- Default view on launch

### **Mobile App Mode**
- 40+ interactive screens in a device frame
- Tab-based navigation
- Native-like interactions
- Touch-optimized interface

**To Access:**
- Click the "Mobile App" button in the switcher
- Displayed in an iPhone-like frame

## 📱 Website Navigation

### **Main Sections**
1. **Hero** - Introduction and brand story
2. **Technology** - Interactive sensor demo
3. **Safety** - Emergency contact builder
4. **Learning** - Educational resources
5. **Hardware** - Product showcase
6. **About** - Team and mission
7. **Contact** - Get in touch form

### **Navigation Methods**
- **Header Menu**: Click section names to jump
- **Scroll**: Natural page scrolling
- **CTA Buttons**: Guided journey through sections
- **Back to Top**: Quick return to hero

### **Interactive Features**
- **Sensor Simulator**: Drag slider to test distance alerts
- **Contact Builder**: Add emergency contacts with drag-and-drop
- **Theme Toggle**: Switch between light/dark modes
- **Language Switch**: Toggle between English/Arabic (RTL/LTR)

## 📲 Mobile App Navigation

### **Onboarding Flow**
1. Welcome screen
2. Accessibility profile setup
3. Hardware pairing wizard

**To Restart Onboarding:**
- Go to Profile tab
- Scroll down and click "Reset Onboarding"

### **Main Tabs** (Bottom Navigation)
1. **Vision** 👁️
   - Real-time sensor visualization
   - Distance monitoring
   - Alert system controls
   - Environmental calibration

2. **Access** 🚪
   - Smart door control
   - Device management
   - Location automation
   - Security settings

3. **Learn** 📖
   - Sign language hub
   - Video tutorials
   - Interactive quizzes
   - Progress tracking

4. **Safety** 🆘
   - Emergency contacts
   - SOS activation
   - Message delivery
   - Platform selection

5. **Profile** 👤
   - User settings
   - Theme switcher
   - Language selector
   - Preferences

## 🎨 Theme System

### **Available Themes**
- **Light Theme**: Vibrant, energetic colors with high contrast
- **Dark Theme**: Sophisticated deep space with glowing accents

### **Switching Themes**
**In Website:**
- Click the sun/moon icon in the header

**In Mobile App:**
- Go to Profile tab
- Toggle "Dark Mode" switch

**Shared State:**
- Theme preference is saved to localStorage
- Consistent across both views
- Smooth 500ms transition animation

## 🌍 Language Support

### **Available Languages**
- **English** (en): Left-to-right layout
- **Arabic** (ar): Right-to-left layout with proper typography

### **Switching Languages**
**In Website:**
- Click the language toggle in the header
- Text morphs between "عربي" and "English"

**In Mobile App:**
- Go to Profile tab
- Tap "Language" option
- Select from bottom sheet

**RTL/LTR Features:**
- Complete layout mirroring
- Culturally appropriate icons
- Proper Arabic ligatures and spacing
- Localized content throughout

## 🎬 Animations & Effects

### **Website Animations**
- **Scroll Triggers**: Elements animate as you scroll
- **Particle Field**: Background particles follow cursor
- **Magnetic Buttons**: Interactive hover effects
- **Gradient Flows**: Animated color transitions
- **3D Transforms**: Depth and perspective effects

### **Mobile Animations**
- **Page Transitions**: Smooth slide animations
- **Micro-interactions**: Button presses, toggles
- **Progress Indicators**: Loading and status updates
- **Celebration Effects**: Achievement unlocks

### **Performance**
- All animations target 60fps
- GPU-accelerated transforms
- Respects `prefers-reduced-motion`
- Optimized for mobile devices

## ⚙️ Settings & Preferences

### **Persistent Settings**
All settings are saved to browser localStorage:
- Theme preference (light/dark)
- Language selection (en/ar)
- Welcome screen dismissal
- Onboarding completion status

### **Clearing Settings**
To reset everything:
```javascript
// Open browser console and run:
localStorage.clear();
location.reload();
```

## 🎯 Interactive Demos

### **Sensor Simulator** (Website - Technology Section)
1. Scroll to Technology section
2. Adjust the distance slider
3. Watch color-coded alerts change:
   - **Green**: Safe (>100cm)
   - **Orange**: Warning (50-100cm)
   - **Red**: Danger (<50cm)
4. Click "Activate Sensor" for live animation

### **Emergency Contact Builder** (Website - Safety Section)
1. Scroll to Safety section
2. Click "Add Emergency Contact"
3. Fill in name and phone number
4. Select platform (WhatsApp/SMS/Call)
5. Drag contacts to reorder priority
6. Click "Test SOS" to see message flow simulation

### **Sign Language Learning** (Mobile - Learn Tab)
1. Switch to Mobile App view
2. Tap Learn tab
3. Browse video tutorials
4. Take interactive quizzes
5. Track your progress

## 🔍 Troubleshooting

### **View Switcher Not Visible**
- Hover your mouse over the top center of the screen
- It will slide down automatically
- The switcher persists in mobile view

### **Mobile Frame Too Large/Small**
- Use browser zoom controls:
  - Zoom out: `Ctrl/Cmd + -`
  - Zoom in: `Ctrl/Cmd + +`
  - Reset: `Ctrl/Cmd + 0`
- Recommended zoom: 80-100%

### **Animations Choppy or Laggy**
- Close unnecessary browser tabs
- Disable browser extensions temporarily
- Check if hardware acceleration is enabled
- Try reducing motion in system preferences

### **Theme Not Switching**
- Check browser console for errors
- Clear localStorage and reload
- Ensure JavaScript is enabled

### **RTL Layout Issues**
- Clear browser cache
- Hard refresh: `Ctrl/Cmd + Shift + R`
- Check HTML `dir` attribute

### **Mobile App Not Scrolling**
- The device frame contains the scrollable area
- Scroll inside the phone screen area
- Some sections have horizontal swipe gestures

## 📊 Performance Tips

### **Optimal Viewing**
- **Browser**: Chrome, Firefox, Safari, Edge (latest versions)
- **Screen Size**: 1280x720 or larger
- **Connection**: Broadband for smooth video backgrounds
- **Hardware**: GPU-accelerated device recommended

### **Low-End Devices**
- The system automatically reduces animation complexity
- Enable "Reduce Motion" in system accessibility settings
- Use light theme for better performance
- Close other applications

## 🎓 Learning the Interface

### **Website Learning Path**
1. Start with Hero section introduction
2. Try the sensor simulator in Technology
3. Add a test contact in Safety section
4. Explore sign language in Learning section
5. View 3D product in Hardware section

### **Mobile App Learning Path**
1. Complete the onboarding flow
2. Explore each tab from left to right
3. Try adding an emergency contact
4. Take a quiz in the Learn tab
5. Customize your profile

## 🆘 Getting Help

### **Built-in Help**
- Tooltip hover hints throughout
- Form validation messages
- Error state explanations
- Success confirmation feedback

### **Documentation**
- `README.md` - Complete feature overview
- `INTEGRATION_GUIDE.md` - This file
- `MOBILE_APP_README.md` - Mobile app specifics

## 🎉 Pro Tips

1. **Keyboard Shortcuts** (Website):
   - `Home`: Jump to top
   - `Tab`: Navigate focusable elements
   - `Enter`: Activate buttons

2. **Hidden Features**:
   - Double-click theme toggle for instant switch
   - Long-press language toggle for reset
   - Shake gesture in mobile (simulated)

3. **Best Experience**:
   - Start with Website view for full impact
   - Try both light and dark themes
   - Test RTL layout in Arabic mode
   - Complete onboarding in mobile view

4. **Sharing**:
   - Settings persist per browser
   - Share URL to start in specific view
   - Theme/language preserved in session

---

**Enjoy exploring the future of accessibility technology!** ✨

For more information, visit the main [README.md](./README.md)
