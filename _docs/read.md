# Calculadora Móvil de Precios para Impresión 3D con Historial Local

Aplicación móvil de alto rendimiento, reactiva y eficiente desarrollada en **Flutter**[cite: 2, 3]. Está orientada a simplificar y automatizar la cotización de trabajos de impresión 3D sin depender de servidores externos, garantizando privacidad absoluta mediante un esquema **100% No-Cloud / No-Auth**[cite: 2, 3]. 

El diseño del sistema y su experiencia de usuario (UX) se rigen por la **Regla del 95%**, optimizando la velocidad operativa del día a día para el operador sin perder la capacidad de cómputo avanzado para configuraciones complejas[cite: 2, 3].

---

## 🚀 Características Clave y Flujo de Usuario

### 2.1. Pantalla de Cálculo Dinámica (Home) y Optimización UX
* **Modo Express (Por Defecto):** Diseñado para cubrir el 95% de las interacciones diarias en el taller[cite: 2]. La interfaz expone únicamente los 3 campos mágicos necesarios para una entrada ultra rápida: **Peso de la pieza (g)**, **Tiempo estimado (hrs/min)** y un control deslizante de **Descuento (%)**[cite: 2].
* **Modo Avanzado Dinámico (Expansión On-the-Fly):** Mediante un botón o chip interactivo (`+ Multi-color / Avanzado`), la UI transforma el campo único de material en una **Lista Dinámica de Materiales** controlada por un `AnimatedList`[cite: 2]. Esto permite añadir filas adicionales para calcular piezas complejas o multi-color (ej. purgas y torres de soporte optimizadas para sistemas como el Anycubic ACE Pro)[cite: 2]. Cada fila permite asociar de forma independiente el filamento específico y su consumo en gramos[cite: 2].
* **Selector de Perfil de Impresora:** Permite cambiar entre diferentes máquinas registradas para mutar dinámicamente el cálculo del consumo eléctrico (Watts) según el hardware que ejecutará el trabajo (ej. Anycubic Kobra 3 vs. otras impresoras)[cite: 2].

### 2.2. Flexibilidad de Datos y Proformas Parciales (Borradores)
* El sistema está blindado contra la fricción de entrada de datos[cite: 2]. El operador puede guardar proformas de manera inmediata en el historial local sin necesidad de rellenar metadatos informativos[cite: 2]. Los campos como `nombre_pieza`, `nombre_cliente` o la asignación estricta a un filamento del catálogo indexado son **completamente opcionales (nullables)**[cite: 2]. Si no se proveen, la aplicación genera un correlativo secuencial automático (Ej: *Cotización #042*) y calcula los costos utilizando un valor de respaldo genérico por gramo configurado en los ajustes[cite: 2].

---

## 🛠️ Stack Tecnológico y Decisiones de Arquitectura

1. **Persistencia Local (Isar Database):** Se prefiere e implementa firmemente **Isar** sobre Hive[cite: 2, 3]. Isar ofrece soporte nativo avanzado de índices, consultas tipadas asíncronas de alta velocidad y la capacidad fundamental de manejar colecciones de objetos embebidos (`@Embedded`) directamente en el documento raíz[cite: 2, 3]. Esto permite que la lista de materiales de una cotización se almacene de forma íntegra y eficiente sin lidiar con mapeos complejos o la escritura manual de múltiples *TypeAdapters* independientes[cite: 2].
2. **Gestión de Estado Reactivo (Riverpod o BLoC / Cubits):** Se establece un enfoque exclusivo de formularios dinámicos e inmutables mediante un `CalculationFormNotifier`[cite: 2, 3]. Cualquier cambio en los inputs numéricos, adición de filamentos o el más mínimo arrastre en el slider de descuento gatilla un evento que recalcula la matriz financiera completa y emite un estado inmutable de manera instantánea[cite: 2, 3]. Se prohíbe el uso de `setState` ineficiente en vistas dinámicas para evitar la degradación del rendimiento de renderizado[cite: 2, 3].
3. **Precisión Numérica Financiera (Anti-Floating Point Error):** Queda estrictamente **prohibido el uso del tipo primitivo `double`** para las operaciones aritméticas y multiplicadores dentro del motor de cálculo[cite: 2, 3]. Debido a cómo Dart maneja el punto flotante, el uso de doubles generaría errores de redondeo indeseados (ej. visualizaciones de valores como `45.000000000000004 BOB`)[cite: 2]. Toda la lógica interna de dinero se procesará utilizando el paquete [`decimal`](https://pub.dev/packages/decimal) o, en su defecto, convirtiendo todas las entradas monetarias a enteros (`int` expresados en centavos/centésimas) y aplicando la máscara de formato `.toStringAsFixed(2)` únicamente en las capas de presentación de la interfaz de usuario[cite: 2, 3].

---

## 📐 Motor de Cálculo (Fórmulas Matemáticas)

Para asegurar la total transparencia en el taller, el motor matemático desglosa los costos de manera reactiva e inmediata[cite: 2]. Ninguna operación se realiza restando linealmente del precio final de venta; todas las variables escalan estrictamente a partir de los costos directos de producción[cite: 2].

### Costo Base
Representa la inversión neta de insumos físicos (acumulado de filamentos) y energéticos requeridos (análisis de luz para Bolivia considerando tarifas residenciales de 0.60 a 0.80 BOB por kWh) para materializar la impresión[cite: 2].
$$Costo\_Base = \left( \sum_{i=1}^{n} Peso\_Gramos_i \times \frac{Precio\_Bobina_i}{Gramos\_Bobina_i} \right) + \left( Tiempo\_Horas \times \frac{Potencia\_Watts}{1000} \times Tarifa\_kWh \right)$$

### Penalización de Ganancia por Descuento
La ganancia aplica un multiplicador directo sobre el Costo Base, penalizado por una regla matemática estricta: cada 1% de descuento comercial reduce el margen global base (por defecto 200%) en 2 puntos porcentuales de utilidad[cite: 2].
$$Ganancia\_Efectiva = Ganancia\_Base\_Global - (Descuento \times 2)$$

### Matriz de Salida
* **Costo Ganancia (Monto):** El valor neto monetario de utilidad neta generado por el trabajo ejecutado[cite: 2].
  $$Monto\_Ganancia = Costo\_Base \times \left( \frac{Ganancia\_Efectiva}{100} \right)$$
* **Precio Total Final:** El precio final sugerido de cara al cliente[cite: 2].
  $$Precio\_Total\_Final = Costo\_Base + Monto\_Ganancia$$

---

## 📂 Módulos de la Aplicación

### Módulo 1: Pantalla de Cálculo (Home)
* Entradas de datos reactivas, selectores dinámicos de modo (Express/Avanzado) y perfiles de hardware[cite: 2].
* Renderizado inmediato y dinámico de la matriz financiera completa al cambiar cualquier variable en los inputs o deslizar el control de descuento[cite: 2].
* Botón de guardado rápido en base de datos local que despliega un modal opcional para adjuntar metadatos de control (Nombre de Pieza, Cliente, e indicador de Venta)[cite: 2].

### Módulo 2: Ajustes (Configuración del Sistema)
* **Parámetros Globales:** Configuración del porcentaje de Ganancia Base inicial y costo de la tarifa eléctrica local ($BOB/kWh$)[cite: 2].
* **Gestor de Catálogo de Filamentos (CRUD):** Registro local de materiales (Nombre, Marca, Precio por bobina, Gramos por bobina) con opción de establecer un material activo por defecto[cite: 2].
* **Gestor de Perfiles de Impresora (CRUD):** Registro de máquinas del taller (Nombre/Modelo, Consumo Promedio en Watts) para indexar coeficientes eléctricos precisos (ej. *Anycubic Kobra 3 - 200W*)[cite: 2].

### Módulo 3: Historial Local Cronológico & Dashboard Estadístico
* Lista ordenada cronológicamente de todas las cotizaciones y proformas registradas[cite: 2]. Las tarjetas resumen muestran la fecha, costo base, precio total cobrado y el título asignado (o ID secuencial si es borrador rápido)[cite: 2].
* **Filtro e Indicador de Venta Realizada:** Cada tarjeta del historial incorpora un toggle rápido o badge táctil interactivo para cambiar el estado de la proforma entre **"Vendida"** o **"No Vendida/Borrador"**[cite: 2].
* **Dashboard de Ganancias Reales:** Panel analítico integrado que consume los datos locales guardados y renderiza un gráfico de barras (usando el paquete `fl_chart`) que contrasta de forma transparente el "Dinero Total Cotizado" frente al "Dinero Real Ganado" (filtrando estrictamente los registros donde `isSold == true`), permitiendo llevar un control riguroso de la rentabilidad del taller[cite: 2].

---

## 📂 Estructura de Datos (Isar Models en Dart)

A continuación se detalla el diseño de las entidades requeridas para la generación de esquemas de persistencia con Isar Database[cite: 2]:

```dart
import 'package:isar/isar.dart';

part 'calculation_models.g.dart';

@collection
class PrinterProfile {
  Id id = Isar.autoIncrement;
  late String name;
  late int averageWatts; // Consumo promedio estimado en Watts (Ej: 200)
}

@embedded
class MaterialInput {
  String? filamentId; // Nullable para proformas rápidas sin catálogo vinculado
  late String label;  // Ej: "PLA Negro" o "Genérico"
  late double weightGrams;
  late double pricePerBobbin;
  late double gramsPerBobbin;
}

@collection
class CalculationRecord {
  Id id = Isar.autoIncrement;
  late DateTime createdAt;
  String? pieceName;   // Nullable para cotizaciones al vuelo
  String? clientName;  // Nullable
  late int printerId;  // ID vinculado al PrinterProfile ejecutor
  late List<MaterialInput> materials; // Colección embebida nativa de Isar
  late double totalHours;
  late double discountPercentage;
  late bool isSold;    // Bandera de control booleano para el Dashboard estadístico
}