// InAppModal.js - Native-feeling in-app message modal

import React, { useEffect, useRef, useState } from 'react';
import {
  View,
  Text,
  Modal,
  TouchableOpacity,
  TouchableWithoutFeedback,
  Animated,
  PanResponder,
  Dimensions,
  SafeAreaView,
  StatusBar,
  Platform,
} from 'react-native';

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window');
const DISMISS_THRESHOLD = 100;
const ANIMATION_DURATION = 300;

const InAppModal = ({
  visible,
  message,
  onClose,
  onActionPress,
  style = {},
  enableSwipeToDismiss = true,
  enableBackdropDismiss = true,
  animationType = 'slide', // 'slide', 'fade', 'scale'
}) => {
  const translateY = useRef(new Animated.Value(SCREEN_HEIGHT)).current;
  const opacity = useRef(new Animated.Value(0)).current;
  const scale = useRef(new Animated.Value(0.8)).current;
  const backdropOpacity = useRef(new Animated.Value(0)).current;
  
  const [isAnimating, setIsAnimating] = useState(false);

  // Create pan responder for swipe-to-dismiss
  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => enableSwipeToDismiss,
      onMoveShouldSetPanResponder: (evt, gestureState) => {
        return enableSwipeToDismiss && Math.abs(gestureState.dy) > 10;
      },
      onPanResponderMove: (evt, gestureState) => {
        // Only allow downward swipes
        if (gestureState.dy > 0) {
          translateY.setValue(gestureState.dy);
        }
      },
      onPanResponderRelease: (evt, gestureState) => {
        if (gestureState.dy > DISMISS_THRESHOLD || gestureState.vy > 0.5) {
          // Dismiss the modal
          handleDismiss();
        } else {
          // Snap back to original position
          Animated.spring(translateY, {
            toValue: 0,
            useNativeDriver: true,
            tension: 100,
            friction: 8,
          }).start();
        }
      },
    })
  ).current;

  useEffect(() => {
    if (visible) {
      showModal();
    } else {
      hideModal();
    }
  }, [visible]);

  const showModal = () => {
    setIsAnimating(true);
    
    // Reset values
    if (animationType === 'slide') {
      translateY.setValue(SCREEN_HEIGHT);
      opacity.setValue(1);
      scale.setValue(1);
    } else if (animationType === 'fade') {
      translateY.setValue(0);
      opacity.setValue(0);
      scale.setValue(1);
    } else if (animationType === 'scale') {
      translateY.setValue(0);
      opacity.setValue(0);
      scale.setValue(0.8);
    }
    
    backdropOpacity.setValue(0);

    // Animate in
    const animations = [
      Animated.timing(backdropOpacity, {
        toValue: 1,
        duration: ANIMATION_DURATION,
        useNativeDriver: true,
      }),
    ];

    if (animationType === 'slide') {
      animations.push(
        Animated.spring(translateY, {
          toValue: 0,
          useNativeDriver: true,
          tension: 100,
          friction: 8,
        })
      );
    } else if (animationType === 'fade') {
      animations.push(
        Animated.timing(opacity, {
          toValue: 1,
          duration: ANIMATION_DURATION,
          useNativeDriver: true,
        })
      );
    } else if (animationType === 'scale') {
      animations.push(
        Animated.parallel([
          Animated.timing(opacity, {
            toValue: 1,
            duration: ANIMATION_DURATION,
            useNativeDriver: true,
          }),
          Animated.spring(scale, {
            toValue: 1,
            useNativeDriver: true,
            tension: 100,
            friction: 8,
          }),
        ])
      );
    }

    Animated.parallel(animations).start(() => {
      setIsAnimating(false);
    });
  };

  const hideModal = () => {
    if (!visible) return;
    
    setIsAnimating(true);

    const animations = [
      Animated.timing(backdropOpacity, {
        toValue: 0,
        duration: ANIMATION_DURATION,
        useNativeDriver: true,
      }),
    ];

    if (animationType === 'slide') {
      animations.push(
        Animated.timing(translateY, {
          toValue: SCREEN_HEIGHT,
          duration: ANIMATION_DURATION,
          useNativeDriver: true,
        })
      );
    } else if (animationType === 'fade') {
      animations.push(
        Animated.timing(opacity, {
          toValue: 0,
          duration: ANIMATION_DURATION,
          useNativeDriver: true,
        })
      );
    } else if (animationType === 'scale') {
      animations.push(
        Animated.parallel([
          Animated.timing(opacity, {
            toValue: 0,
            duration: ANIMATION_DURATION,
            useNativeDriver: true,
          }),
          Animated.timing(scale, {
            toValue: 0.8,
            duration: ANIMATION_DURATION,
            useNativeDriver: true,
          }),
        ])
      );
    }

    Animated.parallel(animations).start(() => {
      setIsAnimating(false);
    });
  };

  const handleDismiss = () => {
    if (isAnimating) return;
    onClose();
  };

  const handleBackdropPress = () => {
    if (enableBackdropDismiss && !isAnimating) {
      handleDismiss();
    }
  };

  const handleActionPress = (action) => {
    if (isAnimating) return;
    
    if (onActionPress) {
      onActionPress(action, message);
    }
    
    // Auto-dismiss after action unless it's a custom action that prevents it
    if (!action.preventDismiss) {
      handleDismiss();
    }
  };

  if (!visible && !isAnimating) {
    return null;
  }

  // Default styling
  const defaultStyles = {
    modal: {
      backgroundColor: '#FFFFFF',
      borderRadius: 16,
      marginHorizontal: 20,
      maxHeight: SCREEN_HEIGHT * 0.8,
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 10 },
      shadowOpacity: 0.25,
      shadowRadius: 20,
      elevation: 10,
    },
    header: {
      paddingHorizontal: 20,
      paddingTop: 20,
      paddingBottom: 8,
    },
    title: {
      fontSize: 18,
      fontWeight: '600',
      color: '#1F2937',
      textAlign: 'center',
    },
    content: {
      paddingHorizontal: 20,
      paddingBottom: 20,
    },
    message: {
      fontSize: 16,
      lineHeight: 24,
      color: '#4B5563',
      textAlign: 'center',
    },
    actions: {
      paddingHorizontal: 20,
      paddingBottom: 20,
      gap: 12,
    },
    primaryButton: {
      backgroundColor: '#3B82F6',
      paddingVertical: 14,
      paddingHorizontal: 20,
      borderRadius: 12,
      alignItems: 'center',
    },
    primaryButtonText: {
      color: '#FFFFFF',
      fontSize: 16,
      fontWeight: '600',
    },
    secondaryButton: {
      backgroundColor: '#F3F4F6',
      paddingVertical: 14,
      paddingHorizontal: 20,
      borderRadius: 12,
      alignItems: 'center',
    },
    secondaryButtonText: {
      color: '#6B7280',
      fontSize: 16,
      fontWeight: '500',
    },
    closeIndicator: {
      width: 40,
      height: 4,
      backgroundColor: '#D1D5DB',
      borderRadius: 2,
      alignSelf: 'center',
      marginTop: 8,
      marginBottom: 12,
    },
  };

  // Merge custom styles
  const mergedStyles = {
    modal: { ...defaultStyles.modal, ...style.modal },
    header: { ...defaultStyles.header, ...style.header },
    title: { ...defaultStyles.title, ...style.title },
    content: { ...defaultStyles.content, ...style.content },
    message: { ...defaultStyles.message, ...style.message },
    actions: { ...defaultStyles.actions, ...style.actions },
    primaryButton: { ...defaultStyles.primaryButton, ...style.primaryButton },
    primaryButtonText: { ...defaultStyles.primaryButtonText, ...style.primaryButtonText },
    secondaryButton: { ...defaultStyles.secondaryButton, ...style.secondaryButton },
    secondaryButtonText: { ...defaultStyles.secondaryButtonText, ...style.secondaryButtonText },
    closeIndicator: { ...defaultStyles.closeIndicator, ...style.closeIndicator },
  };

  // Animation styles
  const animatedModalStyle = {
    transform: [
      { translateY: animationType === 'slide' ? translateY : 0 },
      { scale: animationType === 'scale' ? scale : 1 },
    ],
    opacity: animationType === 'fade' || animationType === 'scale' ? opacity : 1,
  };

  const animatedBackdropStyle = {
    opacity: backdropOpacity,
  };

  return (
    <Modal
      visible={visible || isAnimating}
      transparent
      animationType="none"
      statusBarTranslucent
      onRequestClose={handleDismiss}
    >
      <StatusBar
        backgroundColor="rgba(0, 0, 0, 0.5)"
        barStyle="light-content"
        translucent
      />
      
      {/* Backdrop */}
      <TouchableWithoutFeedback onPress={handleBackdropPress}>
        <Animated.View
          style={[
            {
              flex: 1,
              backgroundColor: 'rgba(0, 0, 0, 0.5)',
              justifyContent: 'center',
              alignItems: 'center',
            },
            animatedBackdropStyle,
          ]}
        >
          {/* Modal Content */}
          <TouchableWithoutFeedback>
            <Animated.View
              style={[mergedStyles.modal, animatedModalStyle]}
              {...(enableSwipeToDismiss ? panResponder.panHandlers : {})}
            >
              {/* Swipe Indicator */}
              {enableSwipeToDismiss && (
                <View style={mergedStyles.closeIndicator} />
              )}

              {/* Header */}
              {message.title && (
                <View style={mergedStyles.header}>
                  <Text 
                    style={mergedStyles.title}
                    accessibilityRole="header"
                    accessibilityLevel={1}
                  >
                    {message.title}
                  </Text>
                </View>
              )}

              {/* Content */}
              <View style={mergedStyles.content}>
                <Text 
                  style={mergedStyles.message}
                  accessibilityRole="text"
                >
                  {message.message}
                </Text>
              </View>

              {/* Actions */}
              {message.actions && message.actions.length > 0 && (
                <View style={mergedStyles.actions}>
                  {message.actions.map((action, index) => {
                    const isPrimary = action.style === 'primary' || index === 0;
                    const buttonStyle = isPrimary ? mergedStyles.primaryButton : mergedStyles.secondaryButton;
                    const textStyle = isPrimary ? mergedStyles.primaryButtonText : mergedStyles.secondaryButtonText;

                    return (
                      <TouchableOpacity
                        key={action.id || index}
                        style={[buttonStyle, action.buttonStyle]}
                        onPress={() => handleActionPress(action)}
                        accessibilityRole="button"
                        accessibilityLabel={action.accessibilityLabel || action.title}
                        accessibilityHint={action.accessibilityHint}
                      >
                        <Text style={[textStyle, action.textStyle]}>
                          {action.title}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              )}

              {/* Default dismiss action if no actions provided */}
              {(!message.actions || message.actions.length === 0) && (
                <View style={mergedStyles.actions}>
                  <TouchableOpacity
                    style={mergedStyles.primaryButton}
                    onPress={handleDismiss}
                    accessibilityRole="button"
                    accessibilityLabel="Dismiss message"
                  >
                    <Text style={mergedStyles.primaryButtonText}>
                      OK
                    </Text>
                  </TouchableOpacity>
                </View>
              )}
            </Animated.View>
          </TouchableWithoutFeedback>
        </Animated.View>
      </TouchableWithoutFeedback>
    </Modal>
  );
};

export default InAppModal;