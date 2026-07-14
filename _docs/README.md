# Calculadora Móvil de Precios para Impresión 3D

Aplicación móvil ágil, reactiva y eficiente desarrollada en **Flutter** orientada a simplificar la cotización de trabajos de impresión 3D sin depender de servidores externos. Optimizada para el flujo de trabajo real del operador mediante la **Regla del 95%**.

## 🚀 Características Clave

* **Regla del 95% (Modo Express):** Interfaz limpia por defecto centrada en los 3 campos mágicos esenciales para velocidad diaria: Peso (g), Tiempo (hrs/min) y Descuento (%).
* **Modo Avanzado Dinámico:** Expansión visual fluida mediante `AnimatedList` para manejar múltiples filamentos en simultáneo (ideal para sistemas multi-color como Anycubic ACE Pro) y selección de perfiles de impresora.
* **Proformas Parciales:** Guarda cotizaciones rápidas en el historial sin requerir metadatos obligatorios (nombres nullables).
* **Control de Ventas & Dashboard:** Un toggle rápido en el historial permite marcar las cotizaciones como "Vendidas" para alimentar un gráfico de barras analítico (`fl_chart`) de Ganancias Reales vs. Cotizadas.
* **Privacidad Absoluta:** Arquitectura 100% local, No Cloud, No Auth.

---

## 🛠️ Stack Tecnológico & Decisiones de Arquitectura

1. **Persistencia Local (Isar Database):** Se prefiere firmemente sobre Hive por su soporte nativo avanzado de índices y manejo elegante de objetos embebidos (`@Embedded`) para la lista de materiales, evitando la creación manual de TypeAdapters.
2. **Gestión de Estado (Riverpod / BLoC):** Enfoque exclusivo de formularios dinámicos e inmutables (`CalculationFormNotifier`) para asegurar un recalculo reactivo inmediato en la UI al mover sliders o añadir filas, eliminando el uso ineficiente de `setState`.
3. **Precisión Numérica Financiera:** Queda estrictamente **prohibido el uso del tipo primitivo `double`** para operaciones aritméticas del motor de cálculo. Se implementa el paquete [`decimal`](https://pub.dev/packages/decimal) o conversión interna a enteros (`int` en centavos) para evitar errores de punto flotante de Dart.

---

## 📂 Estructura de Datos (Isar Models)

```dart
import 'package:isar/isar.dart';

part 'calculation_models.g.dart';

@collection
class PrinterProfile {
  Id id = Isar.autoIncrement;
  late String name;
  late int averageWatts; 
}

@embedded
class MaterialInput {
  String? filamentId; 
  late String label;  
  late double weightGrams;
  late double pricePerBobbin;
  late double gramsPerBobbin;
}

@collection
class CalculationRecord {
  Id id = Isar.autoIncrement;
  late DateTime createdAt;
  String? pieceName;   
  String? clientName;  
  late int printerId;  
  late List<MaterialInput> materials;
  late double totalHours;
  late double discountPercentage;
  late bool isSold;    
}
```

---

## 📐 Motor de Cálculo (Fórmulas Matemáticas)

### Costo Base
$$Costo\_Base = \left( \sum_{i=1}^{n} Peso\_Gramos_i \times \frac{Precio\_Bobina_i}{Gramos\_Bobina_i} \right) + \left( Tiempo\_Horas \times \frac{Potencia\_Watts}{1000} \times Tarifa\_kWh \right)$$

### Penalización de Ganancia por Descuento
$$Ganancia\_Efectiva = Ganancia\_Base\_Global - (Descuento \times 2)$$

### Matriz de Salida
* **Costo Ganancia (Monto):** $Costo\_Base \times (Ganancia\_Efectiva / 100)$
* **Precio Total Final:** $Costo\_Base + Costo\_Ganancia$