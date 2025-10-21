# Refactor Assistant

**Command:** `/refactor`  
**Aliases:** `/rf`  
**Provider:** Anthropic Claude Sonnet  
**Type:** Secondary Agent

## Purpose

Safe code refactoring with diff proposals, test impact analysis, semantic preservation verification, and rollback planning.

## Configuration

```yaml
model:
  provider: anthropic
  name: claude-3-5-sonnet-20241022
  temperature: 0.3
  max_tokens: 8192

safety:
  require_tests: true
  preserve_semantics: true
  verify_compilation: true
  impact_analysis: true

input:
  context_files: 5
```

## System Prompt

```
You are a refactoring expert focused on safe, incremental improvements.

Principles:
- Preserve existing behavior (semantic equivalence)
- Make one change at a time
- Ensure tests cover refactored code
- Highlight breaking changes
- Provide before/after examples
- Assess migration effort

Output safe, reviewable diff proposals.
```

## Output Format

```markdown
# Refactoring Proposal: Extract User Service

## Rationale

The `UserController` has grown to 450 lines with mixed responsibilities:
- HTTP request handling
- Business logic
- Database queries
- Email sending

**Goal**: Extract business logic into `UserService` to improve:
- Testability (mock service in controller tests)
- Reusability (use service from CLI, background jobs)
- Single Responsibility Principle

**Complexity**: Medium  
**Estimated Effort**: 2-3 hours

## Proposed Changes

### Step 1: Create UserService

**New File**: `src/services/user.service.ts`

```typescript
export class UserService {
  constructor(
    private db: Database,
    private emailService: EmailService
  ) {}

  async createUser(data: CreateUserDTO): Promise<User> {
    const existingUser = await this.db.users.findByEmail(data.email);
    if (existingUser) {
      throw new ConflictError('Email already registered');
    }

    const hashedPassword = await bcrypt.hash(data.password, 10);
    const user = await this.db.users.create({
      ...data,
      password: hashedPassword,
    });

    await this.emailService.sendWelcome(user.email);
    return user;
  }

  async updateUser(id: string, data: UpdateUserDTO): Promise<User> {
    const user = await this.db.users.findById(id);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    return this.db.users.update(id, data);
  }
}
```

### Step 2: Refactor Controller

**File**: `src/controllers/user.controller.ts`

```diff
  export class UserController {
-   constructor(private db: Database, private emailService: EmailService) {}
+   constructor(private userService: UserService) {}

    async create(req: Request, res: Response) {
      const data = CreateUserDTO.parse(req.body);
-     
-     const existingUser = await this.db.users.findByEmail(data.email);
-     if (existingUser) {
-       throw new ConflictError('Email already registered');
-     }
-     
-     const hashedPassword = await bcrypt.hash(data.password, 10);
-     const user = await this.db.users.create({
-       ...data,
-       password: hashedPassword,
-     });
-     
-     await this.emailService.sendWelcome(user.email);
+     const user = await this.userService.createUser(data);
      
      res.status(201).json(user);
    }

    async update(req: Request, res: Response) {
      const data = UpdateUserDTO.parse(req.body);
-     
-     const user = await this.db.users.findById(req.params.id);
-     if (!user) {
-       throw new NotFoundError('User not found');
-     }
-     
-     const updated = await this.db.users.update(req.params.id, data);
+     const updated = await this.userService.updateUser(req.params.id, data);
      
      res.json(updated);
    }
  }
```

### Step 3: Update Dependency Injection

**File**: `src/app.ts`

```diff
+ const userService = new UserService(db, emailService);
- const userController = new UserController(db, emailService);
+ const userController = new UserController(userService);
```

## Test Impact

### Existing Tests: Modified

**File**: `tests/controllers/user.controller.test.ts`

- **Status**: ⚠️ Needs updates (mocking strategy changes)
- **Coverage**: Currently 87% → Target 90%

```diff
  describe('UserController', () => {
-   let db: MockDatabase;
-   let emailService: MockEmailService;
+   let userService: MockUserService;
    
    beforeEach(() => {
-     db = createMockDatabase();
-     emailService = createMockEmailService();
+     userService = createMockUserService();
-     controller = new UserController(db, emailService);
+     controller = new UserController(userService);
    });

    it('should create user', async () => {
-     db.users.findByEmail.mockResolvedValue(null);
-     db.users.create.mockResolvedValue(mockUser);
+     userService.createUser.mockResolvedValue(mockUser);
      
      await controller.create(req, res);
      
      expect(res.status).toHaveBeenCalledWith(201);
-     expect(emailService.sendWelcome).toHaveBeenCalled();
    });
  });
```

### New Tests: Required

**File**: `tests/services/user.service.test.ts`

```typescript
describe('UserService', () => {
  it('should hash password before creating user');
  it('should throw ConflictError if email exists');
  it('should send welcome email after creation');
  it('should throw NotFoundError if user not found on update');
});
```

**Coverage Impact**: +134 lines of new test code

## Risks

### Breaking Changes
- ✅ **None** - External API unchanged

### Behavioral Changes
- ✅ **Semantically equivalent** - Same logic, different structure

### Migration Concerns
- ⚠️ **DI Container**: Update dependency injection configuration
- ⚠️ **Background Jobs**: If they import `UserController`, need updates

## Rollback Plan

1. **Git Revert**: Single commit, easy revert
2. **Feature Flag**: Not applicable (internal refactor)
3. **Deployment**: No special considerations

## Checklist

- [ ] Create `UserService` class
- [ ] Write `UserService` unit tests (achieve >85% coverage)
- [ ] Refactor `UserController` to use service
- [ ] Update controller tests with new mocks
- [ ] Update DI container configuration
- [ ] Search codebase for other `UserController` imports
- [ ] Run full test suite
- [ ] Update API documentation (if needed)
- [ ] Code review
- [ ] Merge to main

## Alternatives Considered

### 1. Keep current structure
- ❌ Controller continues to grow
- ❌ Business logic not reusable

### 2. Extract multiple services
- ⚠️ More complex
- ⚠️ Higher migration effort
- ⏭️ Consider for future iteration

### 3. Use repository pattern
- ✅ Good long-term
- ⚠️ Larger refactor scope
- 📝 Document for Phase 2

## Next Steps

1. Create feature branch: `refactor/extract-user-service`
2. Implement Step 1 (create service)
3. Write service tests
4. Implement Step 2 (update controller)
5. Update controller tests
6. Run full test suite
7. Request code review
```

## Usage

```bash
# Propose refactoring
/refactor "Extract user service from controller"

# Quick alias
/rf "Split large function into smaller utilities"

# With context
/refactor "Apply strategy pattern to payment processors" --files src/payments/*.ts
```

## Input Sources

- Target file path
- Code selection (if provided)
- Refactoring goal (user description)
- Context files (up to 5 related files)
- Test files (for impact analysis)

## Safety Checks

1. **Semantic Preservation**: Verify behavior unchanged
2. **Test Coverage**: Ensure refactored code is tested
3. **Compilation**: Check type safety preserved
4. **Impact Analysis**: Identify affected modules

## Rate Limiting

- **Requests per minute**: 20
- **Burst size**: 3

## Caching

- **Enabled**: No (proposals should be fresh)

## Environment Variables

```bash
export ANTHROPIC_API_KEY="your-anthropic-key"
```

## Capabilities

- Code analysis
- Diff generation
- Test impact analysis
- Semantic verification
- Risk assessment
