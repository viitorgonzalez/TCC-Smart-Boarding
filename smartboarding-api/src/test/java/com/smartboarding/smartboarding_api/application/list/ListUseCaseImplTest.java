package com.smartboarding.smartboarding_api.application.list;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.entity.RouteMember;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteMemberRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.in.SendToUserUseCase;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.*;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ListUseCaseImplTest {

    private static final ZoneId ZONE = ZoneId.systemDefault();
    private static final LocalDate TODAY = LocalDate.of(2026, 8, 28);

    @Mock DailyListRepositoryPort dailyListRepository;
    @Mock ListEntryRepositoryPort listEntryRepository;
    @Mock UserRepositoryPort userRepository;
    @Mock SendToUserUseCase sendToUserUseCase;
    @Mock RouteMemberRepositoryPort routeMemberRepository;

    private Clock clockAt(LocalTime time) {
        return Clock.fixed(TODAY.atTime(time).atZone(ZONE).toInstant(), ZONE);
    }

    private ListUseCaseImpl useCaseAt(LocalTime now) {
        return new ListUseCaseImpl(dailyListRepository, listEntryRepository,
                userRepository, sendToUserUseCase, routeMemberRepository, clockAt(now));
    }

    /// Vincula o aluno a rota. Ate a V22 isso vinha da instituicao; agora e um
    /// registro em route_members, criado quando ele usa o codigo da rota.
    private void membroDe(UUID userId, UUID... routeIds) {
        when(routeMemberRepository.findAllByUserId(userId)).thenReturn(
                java.util.Arrays.stream(routeIds)
                        .map(r -> RouteMember.builder().userId(userId).routeId(r).build())
                        .toList());
    }

    private DailyList listWithCloseTime(LocalTime closeTime, LocalDate date) {
        Route route = Route.builder().id(UUID.randomUUID()).name("Rota X")
                .isActive(true).closeTime(closeTime).build();
        return DailyList.builder().id(UUID.randomUUID()).route(route)
                .date(date).status(ListStatus.OPEN).build();
    }

    private UUID stubList(DailyList list) {
        when(dailyListRepository.findById(list.getId())).thenReturn(Optional.of(list));
        // Aluno da própria rota E com perfil completo: isola as regras de
        // horário dos dois guards (rota e perfil). Sem o perfil aqui, todo
        // teste de horário passaria a falhar por um motivo que não é o dele.
        var studentId = UUID.randomUUID();
        when(userRepository.findById(any()))
                .thenReturn(Optional.of(alunoCompleto().id(studentId).build()));
        when(routeMemberRepository.findAllByUserId(any())).thenReturn(java.util.List.of(
                RouteMember.builder().userId(studentId).routeId(list.getRoute().getId()).build()));
        when(listEntryRepository.findByUserIdAndDailyListId(any(), any())).thenReturn(Optional.empty());
        when(listEntryRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        return list.getId();
    }

    @Test
    void alunoNaoEntraEmListaDeOutraRota() {
        var list = listWithCloseTime(LocalTime.of(23, 0), TODAY);
        when(dailyListRepository.findById(list.getId())).thenReturn(Optional.of(list));
        var studentId = UUID.randomUUID();
        when(userRepository.findById(any())).thenReturn(Optional.of(User.builder()
                .id(studentId)
                .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT)
                .build()));
        // O aluno e membro de OUTRA rota, nao da rota desta lista.
        when(routeMemberRepository.findAllByUserId(any())).thenReturn(java.util.List.of(
                RouteMember.builder().userId(studentId).routeId(UUID.randomUUID()).build()));
        var useCase = useCaseAt(LocalTime.of(10, 0));

        assertThatThrownBy(() -> useCase.add(UUID.randomUUID(), list.getId(), TripType.ROUND_TRIP))
                .isInstanceOf(BadRequestException.class);
        verify(listEntryRepository, never()).save(any());
    }

    @Test
    void alunoSemInstituicaoNaoVeListaNenhuma() {
        var list = listWithCloseTime(LocalTime.of(23, 0), TODAY);
        when(dailyListRepository.findAllByDate(TODAY)).thenReturn(java.util.List.of(list));
        var studentId = UUID.randomUUID();
        when(userRepository.findById(studentId)).thenReturn(Optional.of(User.builder()
                .id(studentId)
                .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT)
                .build()));

        assertThat(useCaseAt(LocalTime.of(10, 0)).findTodayLists(studentId)).isEmpty();
    }

    @Test
    void adminVeTodasAsListasDoDia() {
        var a = listWithCloseTime(LocalTime.of(16, 0), TODAY);
        var b = listWithCloseTime(LocalTime.of(23, 0), TODAY);
        when(dailyListRepository.findAllByDate(TODAY)).thenReturn(java.util.List.of(a, b));
        var adminId = UUID.randomUUID();
        when(userRepository.findById(adminId)).thenReturn(Optional.of(User.builder()
                .id(adminId)
                .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.ADMIN)
                .build()));

        assertThat(useCaseAt(LocalTime.of(10, 0)).findTodayLists(adminId)).hasSize(2);
    }

    @Test
    void alunoVeSoAListaDaRotaDaSuaInstituicao() {
        var minha = listWithCloseTime(LocalTime.of(23, 0), TODAY);
        var outra = listWithCloseTime(LocalTime.of(23, 0), TODAY);
        when(dailyListRepository.findAllByDate(TODAY)).thenReturn(java.util.List.of(minha, outra));
        var studentId = UUID.randomUUID();
        when(userRepository.findById(studentId)).thenReturn(Optional.of(User.builder()
                .id(studentId)
                .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT)
                .build()));
        membroDe(studentId, minha.getRoute().getId());

        var result = useCaseAt(LocalTime.of(10, 0)).findTodayLists(studentId);

        assertThat(result).containsExactly(minha);
    }

    @Test
    void entrarAntesDoCloseTimeFunciona() {
        var list = listWithCloseTime(LocalTime.of(16, 0), TODAY);
        var id = stubList(list);
        var useCase = useCaseAt(LocalTime.of(15, 59));

        ListEntry saved = useCase.add(UUID.randomUUID(), id, TripType.ROUND_TRIP);

        assertThat(saved.isActive()).isTrue();
    }

    @Test
    void entrarDepoisDoCloseTimeLancaExcecao() {
        var list = listWithCloseTime(LocalTime.of(16, 0), TODAY);
        var id = stubList(list);
        var useCase = useCaseAt(LocalTime.of(16, 1));

        assertThatThrownBy(() -> useCase.add(UUID.randomUUID(), id, TripType.ROUND_TRIP))
                .isInstanceOf(BadRequestException.class);
        verify(listEntryRepository, never()).save(any());
    }

    @Test
    void closeTimeMaisTardePermiteEntrarDepoisDas16() {
        var list = listWithCloseTime(LocalTime.of(23, 0), TODAY);
        var id = stubList(list);
        var useCase = useCaseAt(LocalTime.of(18, 30));

        ListEntry saved = useCase.add(UUID.randomUUID(), id, TripType.ROUND_TRIP);

        assertThat(saved.isActive()).isTrue();
    }

    @Test
    void entrarEmListaDeOutroDiaLancaExcecao() {
        var list = listWithCloseTime(LocalTime.of(23, 0), TODAY.minusDays(3));
        var id = stubList(list);
        var useCase = useCaseAt(LocalTime.of(10, 0));

        assertThatThrownBy(() -> useCase.add(UUID.randomUUID(), id, TripType.ROUND_TRIP))
                .isInstanceOf(BadRequestException.class);
        verify(listEntryRepository, never()).save(any());
    }

    @Test
    void sairDepoisDoCloseTimeLancaExcecao() {
        var list = listWithCloseTime(LocalTime.of(16, 0), TODAY);
        when(dailyListRepository.findById(list.getId())).thenReturn(Optional.of(list));
        var useCase = useCaseAt(LocalTime.of(17, 0));

        assertThatThrownBy(() -> useCase.remove(UUID.randomUUID(), list.getId()))
                .isInstanceOf(BadRequestException.class);
        verify(listEntryRepository, never()).save(any());
    }

    // ─── Perfil completo como pré-requisito ──────────────────────────────────

    /// O perfil incompleto só barrava a ENTRADA NA ROTA. Entrar na lista do dia
    /// não checava nada, então dava pra estar na chamada com endereço vazio e
    /// telefone em branco -- o motorista com um nome e nenhuma forma de saber
    /// onde a pessoa embarca nem como falar com ela.
    private DailyList listaComAluno(User aluno) {
        var list = listWithCloseTime(LocalTime.of(23, 0), TODAY);
        when(dailyListRepository.findById(list.getId())).thenReturn(Optional.of(list));
        when(userRepository.findById(aluno.getId())).thenReturn(Optional.of(aluno));
        membroDe(aluno.getId(), list.getRoute().getId());
        when(listEntryRepository.findByUserIdAndDailyListId(any(), any()))
                .thenReturn(Optional.empty());
        when(listEntryRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        return list;
    }

    private static User.UserBuilder alunoCompleto() {
        return User.builder()
                .id(UUID.randomUUID())
                .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT)
                .fullName("Fernanda Lima")
                .phone("37999990000")
                .address(com.smartboarding.smartboarding_api.domain.user.entity.Address.builder()
                        .zipCode("35570-000").street("Av. Dr. Arnaldo de Senna")
                        .neighborhood("Água Vermelha").streetNumber("328").build())
                .institutionId(UUID.randomUUID());
    }

    @Test
    void perfilCompletoEntraNaLista() {
        var aluno = alunoCompleto().build();
        var list = listaComAluno(aluno);

        var entry = useCaseAt(LocalTime.of(8, 0)).add(aluno.getId(), list.getId(), TripType.ROUND_TRIP);

        assertThat(entry.isActive()).isTrue();
    }

    @Test
    void perfilSemTelefoneNaoEntra() {
        var aluno = alunoCompleto().phone(null).build();
        var list = listaComAluno(aluno);

        assertThatThrownBy(() ->
                useCaseAt(LocalTime.of(8, 0)).add(aluno.getId(), list.getId(), TripType.ROUND_TRIP))
                .isInstanceOf(BadRequestException.class)
                .hasFieldOrPropertyWithValue("code", "PROFILE_INCOMPLETE_FOR_LIST");
    }

    @Test
    void perfilSemEnderecoCompletoNaoEntra() {
        var aluno = alunoCompleto()
                .address(new com.smartboarding.smartboarding_api.domain.user.entity.Address())
                .build();
        var list = listaComAluno(aluno);

        assertThatThrownBy(() ->
                useCaseAt(LocalTime.of(8, 0)).add(aluno.getId(), list.getId(), TripType.ROUND_TRIP))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void perfilSemInstituicaoNaoEntra() {
        var aluno = alunoCompleto().institutionId(null).build();
        var list = listaComAluno(aluno);

        assertThatThrownBy(() ->
                useCaseAt(LocalTime.of(8, 0)).add(aluno.getId(), list.getId(), TripType.ROUND_TRIP))
                .isInstanceOf(BadRequestException.class);
    }

    /// A mensagem precisa dizer QUAIS campos faltam. "Complete seu perfil"
    /// obriga o aluno a descobrir por tentativa, um campo por viagem perdida.
    @Test
    void oErroDizQuaisCamposFaltam() {
        var aluno = alunoCompleto().phone(null)
                .address(new com.smartboarding.smartboarding_api.domain.user.entity.Address())
                .build();
        var list = listaComAluno(aluno);

        assertThatThrownBy(() ->
                useCaseAt(LocalTime.of(8, 0)).add(aluno.getId(), list.getId(), TripType.ROUND_TRIP))
                .isInstanceOf(BadRequestException.class)
                .extracting(e -> ((BadRequestException) e).getDetails().get("missing"))
                .isEqualTo(java.util.List.of("phone", "address"));
    }

    /// Descrevem a pessoa, não a operação. Travar por eles tiraria alguém do
    /// ônibus por um campo que ninguém usa no dia da viagem.
    @Test
    void nascimentoECursoVaziosNaoImpedem() {
        var aluno = alunoCompleto().birthDate(null).course(null).build();
        var list = listaComAluno(aluno);

        var entry = useCaseAt(LocalTime.of(8, 0)).add(aluno.getId(), list.getId(), TripType.ROUND_TRIP);

        assertThat(entry).isNotNull();
    }

    /// O admin não entra em lista, e travá-lo aqui quebraria qualquer teste ou
    /// rotina que inscreva pela conta dele.
    @Test
    void adminNaoPassaPelaTravaDePerfil() {
        var admin = User.builder().id(UUID.randomUUID())
                .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.ADMIN)
                .fullName("Naiara").build();
        var list = listaComAluno(admin);

        var entry = useCaseAt(LocalTime.of(8, 0)).add(admin.getId(), list.getId(), TripType.ROUND_TRIP);

        assertThat(entry).isNotNull();
    }

    /// Quem já está na lista e só troca ida/volta não pode ser expulso por uma
    /// regra nova: ele entrou quando era permitido, e a direção é editável
    /// enquanto a lista está aberta.
    @Test
    void quemJaEstaNaListaAindaTrocaADirecao() {
        var aluno = alunoCompleto().phone(null).build();
        var list = listaComAluno(aluno);
        var existente = ListEntry.builder().user(aluno).dailyList(list)
                .isActive(true).tripType(TripType.ROUND_TRIP).build();
        when(listEntryRepository.findByUserIdAndDailyListId(aluno.getId(), list.getId()))
                .thenReturn(Optional.of(existente));

        var entry = useCaseAt(LocalTime.of(8, 0))
                .add(aluno.getId(), list.getId(), TripType.TO_CAMPUS);

        assertThat(entry.getTripType()).isEqualTo(TripType.TO_CAMPUS);
    }
}
