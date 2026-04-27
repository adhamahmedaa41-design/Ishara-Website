import { motion } from 'motion/react';
import { useState } from 'react';
import { Target, Users, Lightbulb, Award, ChevronRight } from 'lucide-react';
import { ScrollReveal } from './ScrollReveal';

interface AboutSectionProps {
  language: 'en' | 'ar';
}

export function AboutSection({ language }: AboutSectionProps) {
  const [activeValue, setActiveValue] = useState(0);

  const content = {
    en: {
      title: 'About ISHARA',
      subtitle: 'Pioneering accessibility through innovative technology',
      mission: {
        title: 'Our Mission',
        description: 'To empower visually impaired individuals with cutting-edge wearable technology that enhances independence, safety, and quality of life.'
      },
      vision: {
        title: 'Our Vision',
        description: 'A world where technology eliminates barriers and every person can navigate their environment with confidence and independence.'
      },
      values: [
        {
          icon: Target,
          title: 'Innovation',
          description: 'Pushing the boundaries of assistive technology',
          color: '#14B8A6'
        },
        {
          icon: Users,
          title: 'Empowerment',
          description: 'Enabling independence for all users',
          color: '#F97316'
        },
        {
          icon: Lightbulb,
          title: 'Accessibility',
          description: 'Making technology available to everyone',
          color: '#8B5CF6'
        },
        {
          icon: Award,
          title: 'Excellence',
          description: 'Committed to the highest quality standards',
          color: '#0EA5E9'
        }
      ],
      story: {
        title: 'Our Story',
        paragraphs: [
          'ISHARA was born from a simple yet powerful idea: technology should empower everyone, regardless of their abilities.',
          'Founded in 2023 by a team of engineers, designers, and accessibility advocates, we set out to create wearable technology that truly makes a difference in people\'s lives.',
          'Today, ISHARA smart glasses help thousands of visually impaired individuals navigate their world with confidence and independence.'
        ]
      }
    },
    ar: {
      title: 'عن إشارة',
      subtitle: 'رائدة في إمكانية الوصول من خلال التكنولوجيا المبتكرة',
      mission: {
        title: 'مهمتنا',
        description: 'تمكين الأفراد ضعاف البصر بتقنية يمكن ارتداؤها متطورة تعزز الاستقلالية والسلامة ونوعية الحياة.'
      },
      vision: {
        title: 'رؤيتنا',
        description: 'عالم تلغي فيه التكنولوجيا الحواجز ويمكن لكل شخص التنقل في بيئته بثقة واستقلالية.'
      },
      values: [
        {
          icon: Target,
          title: 'الابتكار',
          description: 'دفع حدود التكنولوجيا المساعدة',
          color: '#14B8A6'
        },
        {
          icon: Users,
          title: 'التمكين',
          description: 'تمكين الاستقلالية لجميع المستخدمين',
          color: '#F97316'
        },
        {
          icon: Lightbulb,
          title: 'إمكانية الوصول',
          description: 'جعل التكنولوجيا متاحة للجميع',
          color: '#8B5CF6'
        },
        {
          icon: Award,
          title: 'التميز',
          description: 'الالتزام بأعلى معايير الجودة',
          color: '#0EA5E9'
        }
      ],
      story: {
        title: 'قصتنا',
        paragraphs: [
          'ولدت إشارة من فكرة بسيطة ولكنها قوية: يجب أن تمكّن التكنولوجيا الجميع، بغض النظر عن قدراتهم.',
          'تأسست في عام 2023 من قبل فريق من المهندسين والمصممين ودعاة إمكانية الوصول، وانطلقنا لإنشاء تقنية يمكن ارتداؤها تحدث فرقًا حقيقيًا في حياة الناس.',
          'اليوم، تساعد نظارات إشارة الذكية آلاف الأفراد ضعاف البصر على التنقل في عالمهم بثقة واستقلالية.'
        ]
      }
    }
  };

  const t = content[language];

  return (
    <section id="about" className="py-32 relative overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-b from-background via-indigo-500/5 to-background" />

      <div className="container mx-auto px-6 relative z-10">
        {/* Header */}
        <ScrollReveal>
          <div className="text-center mb-20">
            <motion.div
              className="inline-block mb-4"
              animate={{
                scale: [1, 1.1, 1],
              }}
              transition={{
                duration: 2,
                repeat: Infinity,
              }}
            >
              <Target className="w-16 h-16 text-indigo-500" />
            </motion.div>
            <h2 className="mb-4">{t.title}</h2>
            <p className="text-muted-foreground text-xl max-w-3xl mx-auto">
              {t.subtitle}
            </p>
          </div>
        </ScrollReveal>

        {/* Mission & Vision */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-20">
          <ScrollReveal direction="left">
            <motion.div
              className="bg-card p-8 rounded-3xl shadow-lg relative overflow-hidden group"
              whileHover={{ y: -10 }}
            >
              <motion.div
                className="absolute inset-0 bg-gradient-to-br from-[#14B8A6]/10 to-transparent"
                initial={{ opacity: 0 }}
                whileHover={{ opacity: 1 }}
              />
              <div className="relative z-10">
                <h3 className="mb-4">{t.mission.title}</h3>
                <p className="text-muted-foreground">{t.mission.description}</p>
              </div>
            </motion.div>
          </ScrollReveal>

          <ScrollReveal direction="right">
            <motion.div
              className="bg-card p-8 rounded-3xl shadow-lg relative overflow-hidden group"
              whileHover={{ y: -10 }}
            >
              <motion.div
                className="absolute inset-0 bg-gradient-to-br from-[#F97316]/10 to-transparent"
                initial={{ opacity: 0 }}
                whileHover={{ opacity: 1 }}
              />
              <div className="relative z-10">
                <h3 className="mb-4">{t.vision.title}</h3>
                <p className="text-muted-foreground">{t.vision.description}</p>
              </div>
            </motion.div>
          </ScrollReveal>
        </div>

        {/* Values */}
        <ScrollReveal>
          <div className="mb-20">
            <h3 className="text-center mb-12">Our Core Values</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              {t.values.map((value, index) => (
                <motion.div
                  key={index}
                  className="bg-card p-6 rounded-2xl cursor-pointer"
                  onClick={() => setActiveValue(index)}
                  whileHover={{ scale: 1.05, y: -10 }}
                  animate={{
                    borderColor: activeValue === index ? value.color : 'transparent',
                    borderWidth: 2,
                  }}
                >
                  <motion.div
                    className="w-16 h-16 rounded-xl mb-4 flex items-center justify-center"
                    style={{
                      background: `linear-gradient(135deg, ${value.color}20, ${value.color}10)`,
                    }}
                    whileHover={{ rotate: 360 }}
                    transition={{ duration: 0.5 }}
                  >
                    <value.icon className="w-8 h-8" style={{ color: value.color }} />
                  </motion.div>
                  <h4 className="mb-2">{value.title}</h4>
                  <p className="text-sm text-muted-foreground">{value.description}</p>
                </motion.div>
              ))}
            </div>
          </div>
        </ScrollReveal>

        {/* Story */}
        <ScrollReveal>
          <div className="bg-card p-12 rounded-3xl shadow-2xl">
            <h3 className="text-center mb-8">{t.story.title}</h3>
            <div className="max-w-3xl mx-auto space-y-6">
              {t.story.paragraphs.map((paragraph, index) => (
                <motion.p
                  key={index}
                  className="text-muted-foreground text-lg leading-relaxed"
                  initial={{ opacity: 0, x: -20 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: index * 0.2 }}
                >
                  <motion.span
                    className="inline-flex items-center gap-2 mr-2"
                    whileHover={{ scale: 1.2 }}
                  >
                    <ChevronRight className="w-5 h-5 text-[#14B8A6]" />
                  </motion.span>
                  {paragraph}
                </motion.p>
              ))}
            </div>
          </div>
        </ScrollReveal>
      </div>
    </section>
  );
}
