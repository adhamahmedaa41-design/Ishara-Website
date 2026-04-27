import { motion, AnimatePresence } from 'motion/react';
import { useState } from 'react';
import { GraduationCap, Trophy, Star, PlayCircle, CheckCircle2, XCircle } from 'lucide-react';
import { ScrollReveal } from './ScrollReveal';

interface LearningSectionProps {
  language: 'en' | 'ar';
}

export function LearningSection({ language }: LearningSectionProps) {
  const [selectedSign, setSelectedSign] = useState(0);
  const [quizActive, setQuizActive] = useState(false);
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [score, setScore] = useState(0);
  const [showResult, setShowResult] = useState(false);
  const [selectedAnswer, setSelectedAnswer] = useState<number | null>(null);

  const content = {
    en: {
      title: 'Learning Hub',
      subtitle: 'Master sign language with interactive lessons',
      signs: [
        { emoji: '👋', name: 'Hello', description: 'Greeting gesture' },
        { emoji: '❤️', name: 'Love', description: 'Express affection' },
        { emoji: '👍', name: 'Good', description: 'Positive response' },
        { emoji: '🙏', name: 'Thank You', description: 'Show gratitude' }
      ],
      practice: 'Practice This Sign',
      startQuiz: 'Start Quiz',
      nextQuestion: 'Next Question',
      finishQuiz: 'Finish Quiz',
      yourScore: 'Your Score',
      questions: [
        {
          question: 'What does this sign mean?',
          sign: '👋',
          answers: ['Hello', 'Goodbye', 'Stop', 'Come'],
          correct: 0
        },
        {
          question: 'Which sign represents "Thank You"?',
          sign: '🙏',
          answers: ['Good', 'Please', 'Thank You', 'Sorry'],
          correct: 2
        },
        {
          question: 'What emotion does this sign show?',
          sign: '❤️',
          answers: ['Anger', 'Love', 'Fear', 'Surprise'],
          correct: 1
        }
      ],
      correct: 'Correct!',
      wrong: 'Wrong!',
      tryAgain: 'Try Again'
    },
    ar: {
      title: 'مركز التعلم',
      subtitle: 'إتقان لغة الإشارة من خلال الدروس التفاعلية',
      signs: [
        { emoji: '👋', name: 'مرحبا', description: 'إيماءة تحية' },
        { emoji: '❤️', name: 'حب', description: 'التعبير عن المودة' },
        { emoji: '👍', name: 'جيد', description: 'استجابة إيجابية' },
        { emoji: '🙏', name: 'شكرا', description: 'إظهار الامتنان' }
      ],
      practice: 'تدرب على هذه الإشارة',
      startQuiz: 'ابدأ الاختبار',
      nextQuestion: 'السؤال التالي',
      finishQuiz: 'إنهاء الاختبار',
      yourScore: 'نتيجتك',
      questions: [
        {
          question: 'ماذا تعني هذه الإشارة؟',
          sign: '👋',
          answers: ['مرحبا', 'وداعا', 'توقف', 'تعال'],
          correct: 0
        },
        {
          question: 'أي إشارة تمثل "شكرا"؟',
          sign: '🙏',
          answers: ['جيد', 'من فضلك', 'شكرا', 'آسف'],
          correct: 2
        },
        {
          question: 'ما هي المشاعر التي تظهرها هذه الإشارة؟',
          sign: '❤️',
          answers: ['غضب', 'حب', 'خوف', 'مفاجأة'],
          correct: 1
        }
      ],
      correct: 'صحيح!',
      wrong: 'خطأ!',
      tryAgain: 'حاول مرة أخرى'
    }
  };

  const t = content[language];

  const handleAnswer = (answerIndex: number) => {
    setSelectedAnswer(answerIndex);
    if (answerIndex === t.questions[currentQuestion].correct) {
      setScore(score + 1);
    }

    setTimeout(() => {
      if (currentQuestion < t.questions.length - 1) {
        setCurrentQuestion(currentQuestion + 1);
        setSelectedAnswer(null);
      } else {
        setShowResult(true);
      }
    }, 1500);
  };

  const resetQuiz = () => {
    setCurrentQuestion(0);
    setScore(0);
    setShowResult(false);
    setSelectedAnswer(null);
    setQuizActive(false);
  };

  return (
    <section id="learning" className="min-h-screen py-32 relative overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-b from-background via-purple-500/5 to-background" />

      <div className="container mx-auto px-6 relative z-10">
        <ScrollReveal>
          <div className="text-center mb-20">
            <motion.div
              className="inline-block mb-4"
              animate={{
                y: [0, -10, 0],
              }}
              transition={{
                duration: 2,
                repeat: Infinity,
              }}
            >
              <GraduationCap className="w-16 h-16 text-purple-500" />
            </motion.div>
            <h2 className="mb-4">{t.title}</h2>
            <p className="text-muted-foreground text-xl max-w-3xl mx-auto">
              {t.subtitle}
            </p>
          </div>
        </ScrollReveal>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          {/* Sign Language Player */}
          <ScrollReveal direction="left">
            <div className="bg-card p-8 rounded-3xl shadow-2xl">
              <h3 className="mb-6">Interactive Sign Language</h3>

              {/* Main Display */}
              <motion.div
                className="relative aspect-square mb-6 rounded-2xl bg-gradient-to-br from-purple-500/20 to-pink-500/20 flex items-center justify-center overflow-hidden"
                whileHover={{ scale: 1.02 }}
              >
                <motion.div
                  key={selectedSign}
                  initial={{ scale: 0, rotate: -180 }}
                  animate={{ scale: 1, rotate: 0 }}
                  exit={{ scale: 0, rotate: 180 }}
                  transition={{ type: 'spring', stiffness: 200, damping: 20 }}
                  className="text-9xl"
                >
                  {t.signs[selectedSign].emoji}
                </motion.div>

                {/* Floating particles */}
                {[...Array(5)].map((_, i) => (
                  <motion.div
                    key={i}
                    className="absolute w-4 h-4 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full"
                    animate={{
                      x: [0, Math.random() * 100 - 50],
                      y: [0, Math.random() * 100 - 50],
                      opacity: [1, 0],
                      scale: [1, 0],
                    }}
                    transition={{
                      duration: 2,
                      repeat: Infinity,
                      delay: i * 0.4,
                    }}
                    style={{
                      left: `${Math.random() * 100}%`,
                      top: `${Math.random() * 100}%`,
                    }}
                  />
                ))}
              </motion.div>

              {/* Sign Info */}
              <div className="text-center mb-6">
                <h3 className="mb-2">{t.signs[selectedSign].name}</h3>
                <p className="text-muted-foreground">{t.signs[selectedSign].description}</p>
              </div>

              {/* Sign Selector */}
              <div className="grid grid-cols-4 gap-3">
                {t.signs.map((sign, index) => (
                  <motion.button
                    key={index}
                    onClick={() => setSelectedSign(index)}
                    className={`p-4 rounded-xl transition-all ${
                      selectedSign === index
                        ? 'bg-gradient-to-br from-purple-500 to-pink-500 text-white'
                        : 'bg-secondary hover:bg-secondary/70'
                    }`}
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                  >
                    <div className="text-4xl mb-2">{sign.emoji}</div>
                    <div className="text-xs">{sign.name}</div>
                  </motion.button>
                ))}
              </div>

              {/* Practice Button */}
              <motion.button
                className="w-full mt-6 py-4 bg-gradient-to-r from-purple-500 to-pink-500 text-white rounded-xl flex items-center justify-center gap-2"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                <PlayCircle className="w-5 h-5" />
                {t.practice}
              </motion.button>
            </div>
          </ScrollReveal>

          {/* Quiz Section */}
          <ScrollReveal direction="right">
            <div className="bg-card p-8 rounded-3xl shadow-2xl">
              <div className="flex items-center justify-between mb-6">
                <h3>Learning Quiz</h3>
                <div className="flex items-center gap-2">
                  <Trophy className="w-6 h-6 text-yellow-500" />
                  <span className="text-2xl">{score}</span>
                </div>
              </div>

              {!quizActive && !showResult && (
                <motion.div
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="text-center py-12"
                >
                  <Trophy className="w-20 h-20 text-yellow-500 mx-auto mb-6" />
                  <p className="text-muted-foreground mb-6">
                    Test your knowledge with our interactive quiz!
                  </p>
                  <motion.button
                    onClick={() => setQuizActive(true)}
                    className="px-8 py-4 bg-gradient-to-r from-purple-500 to-pink-500 text-white rounded-xl"
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                  >
                    {t.startQuiz}
                  </motion.button>
                </motion.div>
              )}

              {quizActive && !showResult && (
                <AnimatePresence mode="wait">
                  <motion.div
                    key={currentQuestion}
                    initial={{ opacity: 0, x: 50 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -50 }}
                  >
                    {/* Progress */}
                    <div className="mb-6">
                      <div className="flex justify-between text-sm text-muted-foreground mb-2">
                        <span>Question {currentQuestion + 1} of {t.questions.length}</span>
                        <span>{score} correct</span>
                      </div>
                      <div className="h-2 bg-secondary rounded-full overflow-hidden">
                        <motion.div
                          className="h-full bg-gradient-to-r from-purple-500 to-pink-500"
                          initial={{ width: 0 }}
                          animate={{ width: `${((currentQuestion + 1) / t.questions.length) * 100}%` }}
                        />
                      </div>
                    </div>

                    {/* Question */}
                    <div className="mb-8">
                      <p className="mb-6">{t.questions[currentQuestion].question}</p>
                      <div className="text-9xl text-center mb-6">
                        {t.questions[currentQuestion].sign}
                      </div>
                    </div>

                    {/* Answers */}
                    <div className="space-y-3">
                      {t.questions[currentQuestion].answers.map((answer, index) => {
                        const isSelected = selectedAnswer === index;
                        const isCorrect = index === t.questions[currentQuestion].correct;
                        const showFeedback = selectedAnswer !== null;

                        return (
                          <motion.button
                            key={index}
                            onClick={() => handleAnswer(index)}
                            disabled={selectedAnswer !== null}
                            className={`w-full p-4 rounded-xl text-left transition-all ${
                              showFeedback
                                ? isSelected
                                  ? isCorrect
                                    ? 'bg-green-500/20 border-2 border-green-500'
                                    : 'bg-red-500/20 border-2 border-red-500'
                                  : isCorrect
                                  ? 'bg-green-500/20 border-2 border-green-500'
                                  : 'bg-secondary'
                                : 'bg-secondary hover:bg-secondary/70'
                            }`}
                            whileHover={selectedAnswer === null ? { scale: 1.02, x: 10 } : {}}
                            whileTap={selectedAnswer === null ? { scale: 0.98 } : {}}
                          >
                            <div className="flex items-center justify-between">
                              <span>{answer}</span>
                              {showFeedback && isSelected && (
                                <motion.div
                                  initial={{ scale: 0 }}
                                  animate={{ scale: 1 }}
                                >
                                  {isCorrect ? (
                                    <CheckCircle2 className="w-6 h-6 text-green-500" />
                                  ) : (
                                    <XCircle className="w-6 h-6 text-red-500" />
                                  )}
                                </motion.div>
                              )}
                              {showFeedback && !isSelected && isCorrect && (
                                <CheckCircle2 className="w-6 h-6 text-green-500" />
                              )}
                            </div>
                          </motion.button>
                        );
                      })}
                    </div>
                  </motion.div>
                </AnimatePresence>
              )}

              {showResult && (
                <motion.div
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  className="text-center py-12"
                >
                  <motion.div
                    animate={{
                      rotate: [0, 360],
                      scale: [1, 1.2, 1],
                    }}
                    transition={{
                      duration: 1,
                    }}
                  >
                    <Trophy className="w-24 h-24 text-yellow-500 mx-auto mb-6" />
                  </motion.div>
                  <h3 className="mb-2">{t.yourScore}</h3>
                  <div className="text-6xl mb-6 bg-gradient-to-r from-purple-500 to-pink-500 bg-clip-text text-transparent">
                    {score} / {t.questions.length}
                  </div>
                  <div className="flex gap-2 mb-6 justify-center">
                    {[...Array(t.questions.length)].map((_, i) => (
                      <Star
                        key={i}
                        className={`w-8 h-8 ${
                          i < score ? 'text-yellow-500 fill-yellow-500' : 'text-muted'
                        }`}
                      />
                    ))}
                  </div>
                  <motion.button
                    onClick={resetQuiz}
                    className="px-8 py-4 bg-gradient-to-r from-purple-500 to-pink-500 text-white rounded-xl"
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                  >
                    {t.tryAgain}
                  </motion.button>
                </motion.div>
              )}
            </div>
          </ScrollReveal>
        </div>
      </div>
    </section>
  );
}
