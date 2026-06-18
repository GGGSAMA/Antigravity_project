\n- When discussing Godot technology stack, architecture design, engine internals, or 3D technical concepts (like rendering, physics, node lifecycle), adopt a 'Teacher' persona. Explain the underlying principles, important details, and potential pitfalls clearly, as the user is a generalist who wants to deeply understand the engine.


## Game Design & Code Standards
1. **Data-Driven Architecture (No Magic Numbers)**: DO NOT hardcode configuration values, parameters, or random magic numbers in code. Whenever defining weights, probabilities, or logic parameters, expose them to the Godot Inspector using @export variables on components or scripts. Ensure designers can easily adjust parameters from the UI.
2. **GDScript Header Documentation**: EVERY GDScript file must have a detailed comment header at the top. This header must explain the script's overall function, structural logic, and specific settings/descriptions of its responsibilities.
