# Repository Guidelines

## Project Structure & Module Organization
This repository is a multi-module Maven project for the RuoYi admin platform. `ruoyi-admin/` is the runnable Spring Boot web app and contains the entry point at `src/main/java/com/ruoyi/RuoYiApplication.java`, plus `application.yml`, Thymeleaf templates, static assets, and MyBatis config under `src/main/resources/`. Shared code lives in `ruoyi-common/` and `ruoyi-framework/`. Business entities, mappers, and services are in `ruoyi-system/`. Scheduled jobs are in `ruoyi-quartz/`, and code-generation templates live in `ruoyi-generator/src/main/resources/vm/`. Database scripts are kept in `sql/`.

## Build, Test, and Development Commands
Use Maven from the repository root:

- `mvn clean package` builds all modules and produces the admin artifact.
- `mvn clean test` runs the current test suite across modules.
- `mvn -pl ruoyi-admin -am spring-boot:run` starts the web app locally with required dependent modules.
- `mvn -pl ruoyi-admin -am package` rebuilds only the admin app and its dependencies.

Before running locally, review `ruoyi-admin/src/main/resources/application.yml` and `application-druid.yml` for database and Redis-related settings.

## Coding Style & Naming Conventions
Follow existing Java conventions in the repo: 4-space indentation, UTF-8 source files, and package names under `com.ruoyi.*`. Keep classes in role-specific packages such as `domain`, `mapper`, `service`, and `controller`. Use `UpperCamelCase` for classes, `lowerCamelCase` for methods and fields, and preserve existing suffixes like `ServiceImpl`, `Mapper`, and `Controller`. No formatter or linter is configured in Maven, so match nearby code closely and keep imports and annotations consistent with surrounding files.

## Testing Guidelines
There are currently no committed `src/test` directories, so treat test coverage as additive work. For new logic, add focused unit or integration tests under `src/test/java` in the affected module and run them with `mvn test`. If automated coverage is not practical, document manual verification steps in the pull request, especially for login, scheduling, generator, or SQL-backed changes.

## Commit & Pull Request Guidelines
Recent history uses short, imperative subjects, often in Chinese, for example `修复更多菜单鼠标离开后不自动关闭的问题` and `update application`. Keep commit titles brief, descriptive, and scoped to one change. Pull requests should include a concise summary, affected modules, configuration or SQL changes, linked issues, and screenshots for UI updates. Call out any required migration steps explicitly.
