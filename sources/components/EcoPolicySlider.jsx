import React, { useState, useEffect } from 'react';
import { View, Text, Slider, StyleSheet, TouchableOpacity } from 'react-native';

const EcoPolicySlider = ({ ecoBusRef }) => {
  const [vegetationProtection, setVegetationProtection] = useState(0);
  const [emissionReduction, setEmissionReduction] = useState(0);
  const [emergencyBudget, setEmergencyBudget] = useState(0);
  const [constructionSubsidy, setConstructionSubsidy] = useState(0);

  // 模拟与ECO-BUS的连接
  useEffect(() => {
    // 在实际实现中，这里会调用native模块来更新ECO-BUS的政策向量
    updateEcoBusPolicy();
  }, [vegetationProtection, emissionReduction, emergencyBudget, constructionSubsidy]);

  const updateEcoBusPolicy = () => {
    // 在实际实现中，这里会通过某种方式（如Native Module）将政策值传递给C++的ECO-BUS
    console.log('Updating ECO-BUS policy vector:', {
      vegetationProtection,
      emissionReduction,
      emergencyBudget,
      constructionSubsidy
    });

    // 模拟：如果ecoBusRef存在，则调用其更新方法
    if (ecoBusRef && ecoBusRef.current) {
      ecoBusRef.current.setPolicyVector({
        vegetation_protection: vegetationProtection,
        emission_reduction: emissionReduction,
        emergency_budget: emergencyBudget,
        construction_subsidy: constructionSubsidy
      });
    }
  };

  const formatValue = (value) => {
    return (value * 100).toFixed(0) + '%';
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>ECO-BUS Policy Controls</Text>
      
      <View style={styles.sliderContainer}>
        <Text style={styles.label}>Vegetation Protection: {formatValue(vegetationProtection)}</Text>
        <Slider
          style={styles.slider}
          minimumValue={0}
          maximumValue={1}
          value={vegetationProtection}
          onValueChange={setVegetationProtection}
          step={0.05}
          thumbStyle={styles.thumb}
          trackStyle={styles.track}
        />
      </View>
      
      <View style={styles.sliderContainer}>
        <Text style={styles.label}>Emission Reduction: {formatValue(emissionReduction)}</Text>
        <Slider
          style={styles.slider}
          minimumValue={0}
          maximumValue={1}
          value={emissionReduction}
          onValueChange={setEmissionReduction}
          step={0.05}
          thumbStyle={styles.thumb}
          trackStyle={styles.track}
        />
      </View>
      
      <View style={styles.sliderContainer}>
        <Text style={styles.label}>Emergency Budget: {formatValue(emergencyBudget)}</Text>
        <Slider
          style={styles.slider}
          minimumValue={0}
          maximumValue={1}
          value={emergencyBudget}
          onValueChange={setEmergencyBudget}
          step={0.05}
          thumbStyle={styles.thumb}
          trackStyle={styles.track}
        />
      </View>
      
      <View style={styles.sliderContainer}>
        <Text style={styles.label}>Construction Subsidy: {formatValue(constructionSubsidy)}</Text>
        <Slider
          style={styles.slider}
          minimumValue={0}
          maximumValue={1}
          value={constructionSubsidy}
          onValueChange={setConstructionSubsidy}
          step={0.05}
          thumbStyle={styles.thumb}
          trackStyle={styles.track}
        />
      </View>

      <TouchableOpacity style={styles.resetButton} onPress={() => {
        setVegetationProtection(0);
        setEmissionReduction(0);
        setEmergencyBudget(0);
        setConstructionSubsidy(0);
      }}>
        <Text style={styles.resetButtonText}>Reset Policies</Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
    padding: 16,
    borderRadius: 8,
    margin: 8,
    minWidth: 300,
  },
  title: {
    color: '#4A90E2',
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 16,
    textAlign: 'center',
  },
  sliderContainer: {
    marginBottom: 16,
  },
  label: {
    color: 'white',
    marginBottom: 8,
    fontSize: 14,
  },
  slider: {
    width: '100%',
    height: 40,
  },
  thumb: {
    backgroundColor: '#4A90E2',
  },
  track: {
    height: 2,
    borderRadius: 1,
  },
  resetButton: {
    backgroundColor: '#d32f2f',
    padding: 12,
    borderRadius: 6,
    alignItems: 'center',
    marginTop: 16,
  },
  resetButtonText: {
    color: 'white',
    fontWeight: 'bold',
  },
});

export default EcoPolicySlider;