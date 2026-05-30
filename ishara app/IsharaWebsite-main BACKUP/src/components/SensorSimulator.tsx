import { motion } from 'motion/react';
import { useState } from 'react';
import { Activity, AlertTriangle, CheckCircle2 } from 'lucide-react';

interface SensorSimulatorProps {
  language: 'en' | 'ar';
}

export function SensorSimulator({ language }: SensorSimulatorProps) {
  const [distance, setDistance] = useState(150);
  const [isActive, setIsActive] = useState(false);

  const getAlertLevel = () => {
    if (distance < 50) return { color: '#EF4444', level: 'danger', text: language === 'en' ? 'DANGER' : 'خطر' };
    if (distance < 100) return { color: '#F97316', level: 'warning', text: language === 'en' ? 'WARNING' : 'تحذير' };
    return { color: '#14B8A6', level: 'safe', text: language === 'en' ? 'SAFE' : 'آمن' };
  };

  const alert = getAlertLevel();

  const content = {
    en: {
      title: 'Interactive Sensor Demo',
      subtitle: 'Adjust the distance slider to see real-time alerts',
      distance: 'Distance',
      cm: 'cm',
      activate: 'Activate Sensor',
      deactivate: 'Deactivate Sensor',
      detecting: 'Detecting obstacles...'
    },
    ar: {
      title: 'عرض توضيحي تفاعلي للمستشعر',
      subtitle: 'اضبط شريط تمرير المسافة لرؤية التنبيهات في الوقت الفعلي',
      distance: 'المسافة',
      cm: 'سم',
      activate: 'تفعيل المستشعر',
      deactivate: 'إلغاء تفعيل المستشعر',
      detecting: 'اكتشاف العقبات...'
    }
  };

  const t = content[language];

  return (
    <div className="relative bg-card rounded-3xl p-8 shadow-2xl overflow-hidden">
      {/* Background waves */}
      <motion.div
        className="absolute inset-0 opacity-10"
        style={{
          background: `radial-gradient(circle at 50% 50%, ${alert.color} 0%, transparent 70%)`
        }}
        animate={{
          scale: isActive ? [1, 1.2, 1] : 1,
        }}
        transition={{
          duration: 2,
          repeat: isActive ? Infinity : 0,
        }}
      />

      <div className="relative z-10">
        <div className="text-center mb-8">
          <h3 className="mb-2">{t.title}</h3>
          <p className="text-muted-foreground">{t.subtitle}</p>
        </div>

        {/* Sensor Visualization */}
        <div className="relative h-80 mb-8 bg-secondary/50 rounded-2xl overflow-hidden">
          {/* Radar circles */}
          <div className="absolute inset-0 flex items-center justify-center">
            {[0, 1, 2, 3].map((i) => (
              <motion.div
                key={i}
                className="absolute border-2 rounded-full"
                style={{
                  width: `${(i + 1) * 25}%`,
                  height: `${(i + 1) * 25}%`,
                  borderColor: alert.color,
                  opacity: 0.3,
                }}
                animate={isActive ? {
                  scale: [1, 1.2, 1],
                  opacity: [0.3, 0.1, 0.3],
                } : {}}
                transition={{
                  duration: 2,
                  delay: i * 0.2,
                  repeat: isActive ? Infinity : 0,
                }}
              />
            ))}
          </div>

          {/* Center (glasses) */}
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-6xl">
            👓
          </div>

          {/* Obstacle */}
          <motion.div
            className="absolute top-1/2 -translate-y-1/2 w-16 h-16 rounded-lg bg-gradient-to-br from-[#14B8A6] to-[#F97316] flex items-center justify-center text-white"
            style={{
              left: `${50 + (distance / 200 * 40)}%`,
            }}
            animate={isActive ? {
              y: [-10, 10, -10],
            } : {}}
            transition={{
              duration: 2,
              repeat: isActive ? Infinity : 0,
            }}
          >
            <AlertTriangle className="w-8 h-8" />
          </motion.div>

          {/* Detection wave */}
          {isActive && (
            <motion.div
              className="absolute top-1/2 left-1/2 -translate-y-1/2"
              initial={{ x: 0, opacity: 0.8, scale: 0.5 }}
              animate={{
                x: distance / 2,
                opacity: 0,
                scale: 2,
              }}
              transition={{
                duration: 1,
                repeat: Infinity,
                ease: 'easeOut',
              }}
            >
              <div
                className="w-20 h-20 rounded-full"
                style={{
                  background: `radial-gradient(circle, ${alert.color} 0%, transparent 70%)`,
                }}
              />
            </motion.div>
          )}
        </div>

        {/* Alert Status */}
        <motion.div
          className="text-center mb-6 p-6 rounded-2xl"
          style={{
            backgroundColor: `${alert.color}20`,
            borderColor: alert.color,
            borderWidth: 2,
          }}
          animate={{
            boxShadow: isActive ? [
              `0 0 20px ${alert.color}40`,
              `0 0 40px ${alert.color}60`,
              `0 0 20px ${alert.color}40`,
            ] : 'none',
          }}
          transition={{
            duration: 1,
            repeat: isActive ? Infinity : 0,
          }}
        >
          <div className="flex items-center justify-center gap-3 mb-2">
            {alert.level === 'safe' && <CheckCircle2 className="w-8 h-8" style={{ color: alert.color }} />}
            {alert.level === 'warning' && <AlertTriangle className="w-8 h-8" style={{ color: alert.color }} />}
            {alert.level === 'danger' && <Activity className="w-8 h-8" style={{ color: alert.color }} />}
            <span className="text-3xl" style={{ color: alert.color, fontWeight: 600 }}>
              {alert.text}
            </span>
          </div>
          {isActive && (
            <motion.p
              className="text-sm text-muted-foreground"
              animate={{ opacity: [1, 0.5, 1] }}
              transition={{ duration: 1.5, repeat: Infinity }}
            >
              {t.detecting}
            </motion.p>
          )}
        </motion.div>

        {/* Distance Control */}
        <div className="mb-6">
          <div className="flex justify-between items-center mb-3">
            <span>{t.distance}</span>
            <span className="text-2xl" style={{ color: alert.color, fontWeight: 600 }}>
              {distance} {t.cm}
            </span>
          </div>
          <input
            type="range"
            min="0"
            max="200"
            value={distance}
            onChange={(e) => setDistance(Number(e.target.value))}
            className="w-full h-3 rounded-full appearance-none cursor-pointer"
            style={{
              background: `linear-gradient(to right, #EF4444 0%, #F97316 50%, #14B8A6 100%)`,
            }}
          />
        </div>

        {/* Activate Button */}
        <motion.button
          onClick={() => setIsActive(!isActive)}
          className="w-full py-4 rounded-xl text-white"
          style={{
            background: isActive 
              ? 'linear-gradient(135deg, #EF4444, #F97316)'
              : 'linear-gradient(135deg, #14B8A6, #0EA5E9)',
          }}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
        >
          {isActive ? t.deactivate : t.activate}
        </motion.button>
      </div>
    </div>
  );
}
