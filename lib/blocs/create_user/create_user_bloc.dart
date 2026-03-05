import 'package:flutter_bloc/flutter_bloc.dart';
import 'create_user_event.dart';
import 'create_user_state.dart';

class CreateUserBloc extends Bloc<CreateUserEvent, CreateUserState> {
  CreateUserBloc() : super(const CreateUserFormState()) {
    on<ValidateFieldEvent>(_onValidateField);
    on<ValidateConfirmPasswordEvent>(_onValidateConfirmPassword);
    on<CreateUserSubmitEvent>(_onCreateUser);
    on<ResetFormEvent>(_onResetForm);
  }

  /// Valida um campo individual
  Future<void> _onValidateField(
    ValidateFieldEvent event,
    Emitter<CreateUserState> emit,
  ) async {
    if (state is! CreateUserFormState) {
      emit(const CreateUserFormState());
      return;
    }

    final currentState = state as CreateUserFormState;

    switch (event.fieldName) {
      case 'name':
        emit(_validateName(currentState, event.value));
        break;
      case 'email':
        emit(_validateEmail(currentState, event.value));
        break;
      case 'password':
        emit(_validatePassword(currentState, event.value));
        break;
      case 'role':
        emit(_validateRole(currentState, event.value));
        break;
    }
  }

  /// Valida confirmação de senha
  Future<void> _onValidateConfirmPassword(
    ValidateConfirmPasswordEvent event,
    Emitter<CreateUserState> emit,
  ) async {
    if (state is! CreateUserFormState) {
      emit(const CreateUserFormState());
      return;
    }

    final currentState = state as CreateUserFormState;

    if (event.confirmPassword.isEmpty) {
      emit(currentState.copyWith(
        confirmPasswordError: 'Por favor, confirme a senha',
        confirmPasswordValid: false,
      ));
    } else if (event.confirmPassword != event.password) {
      emit(currentState.copyWith(
        confirmPasswordError: 'As senhas não coincidem',
        confirmPasswordValid: false,
      ));
    } else {
      emit(currentState.copyWith(
        clearConfirmPasswordError: true,
        confirmPasswordValid: true,
      ));
    }
  }

  /// Cria o usuário
  Future<void> _onCreateUser(
    CreateUserSubmitEvent event,
    Emitter<CreateUserState> emit,
  ) async {
    // Valida todos os campos primeiro
    var formState = const CreateUserFormState();
    formState = _validateName(formState, event.name);
    formState = _validateEmail(formState, event.email);
    formState = _validatePassword(formState, event.password);
    formState = _validateRole(formState, event.role);

    // Valida confirmação de senha
    if (event.confirmPassword.isEmpty) {
      formState = formState.copyWith(
        confirmPasswordError: 'Por favor, confirme a senha',
        confirmPasswordValid: false,
      );
    } else if (event.confirmPassword != event.password) {
      formState = formState.copyWith(
        confirmPasswordError: 'As senhas não coincidem',
        confirmPasswordValid: false,
      );
    } else {
      formState = formState.copyWith(
        clearConfirmPasswordError: true,
        confirmPasswordValid: true,
      );
    }

    // Se algum campo for inválido, emite o estado com erros
    if (!formState.isFormValid) {
      emit(formState);
      return;
    }

    // Tudo válido, prossegue com a criação
    emit(const CreateUserLoading());

    try {
      // Simula cadastro no repositório
      await Future.delayed(const Duration(seconds: 1));

      // Em produção, chamaria: await userRepository.createUser(...)

      emit(CreateUserSuccess(event.name));
    } catch (e) {
      emit(CreateUserError('Erro ao cadastrar usuário: ${e.toString()}'));
      // Volta para o estado do formulário
      emit(formState);
    }
  }

  /// Reseta o formulário
  Future<void> _onResetForm(
    ResetFormEvent event,
    Emitter<CreateUserState> emit,
  ) async {
    emit(const CreateUserFormState());
  }

  // Métodos de validação privados

  CreateUserFormState _validateName(CreateUserFormState state, String value) {
    if (value.isEmpty) {
      return state.copyWith(
        nameError: 'Por favor, informe o nome',
        nameValid: false,
      );
    } else if (value.length < 3) {
      return state.copyWith(
        nameError: 'Nome deve ter pelo menos 3 caracteres',
        nameValid: false,
      );
    } else {
      return state.copyWith(
        clearNameError: true,
        nameValid: true,
      );
    }
  }

  CreateUserFormState _validateEmail(CreateUserFormState state, String value) {
    if (value.isEmpty) {
      return state.copyWith(
        emailError: 'Por favor, informe o email',
        emailValid: false,
      );
    } else if (!value.contains('@')) {
      return state.copyWith(
        emailError: 'Email inválido',
        emailValid: false,
      );
    } else {
      return state.copyWith(
        clearEmailError: true,
        emailValid: true,
      );
    }
  }

  CreateUserFormState _validatePassword(
      CreateUserFormState state, String value) {
    if (value.isEmpty) {
      return state.copyWith(
        passwordError: 'Por favor, informe a senha',
        passwordValid: false,
      );
    } else if (value.length < 6) {
      return state.copyWith(
        passwordError: 'Senha deve ter pelo menos 6 caracteres',
        passwordValid: false,
      );
    } else {
      return state.copyWith(
        clearPasswordError: true,
        passwordValid: true,
      );
    }
  }

  CreateUserFormState _validateRole(CreateUserFormState state, String value) {
    if (value.isEmpty) {
      return state.copyWith(
        roleError: 'Por favor, informe o cargo',
        roleValid: false,
      );
    } else {
      return state.copyWith(
        clearRoleError: true,
        roleValid: true,
      );
    }
  }
}
