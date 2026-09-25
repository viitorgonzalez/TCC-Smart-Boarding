package com.smartboarding.smartboarding_api.infrastructure.route;

import com.smartboarding.smartboarding_api.domain.route.port.out.GeoPoint;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class OsrmRoutePlannerAdapterTest {

    private static final GeoPoint RODOVIARIA = new GeoPoint(-20.4644, -45.4267);
    private static final GeoPoint UNIFOR = new GeoPoint(-20.4700, -45.4300);

    private MockRestServiceServer server;
    private OsrmRoutePlannerAdapter adapter;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder().baseUrl("http://osrm.local");
        server = MockRestServiceServer.bindTo(builder).build();
        adapter = new OsrmRoutePlannerAdapter(builder.build());
    }

    /// A armadilha: o OSRM espera **longitude,latitude**, invertido em relação
    /// ao que quase toda API de mapa usa. Trocar a ordem calcula um trajeto em
    /// outro continente e devolve um número — sem erro nenhum pra avisar.
    @Test
    void mandaLongitudeAntesDeLatitude() {
        server.expect(requestTo(
                        "http://osrm.local/route/v1/driving/-45.4267,-20.4644;-45.43,-20.47?overview=false"))
                .andRespond(withSuccess("""
                        {"routes":[{"legs":[{"duration":600.0}]}]}
                        """, MediaType.APPLICATION_JSON));

        assertThat(adapter.legDurationsSeconds(List.of(RODOVIARIA, UNIFOR)))
                .contains(List.of(600.0));
        server.verify();
    }

    @Test
    void devolveUmaDuracaoPorTrecho() {
        server.expect(requestTo(org.hamcrest.Matchers.containsString("/route/v1/driving/")))
                .andRespond(withSuccess("""
                        {"routes":[{"legs":[{"duration":300.0},{"duration":420.0}]}]}
                        """, MediaType.APPLICATION_JSON));

        assertThat(adapter.legDurationsSeconds(
                List.of(RODOVIARIA, UNIFOR, new GeoPoint(-20.48, -45.44))))
                .contains(List.of(300.0, 420.0));
    }

    /// Sem SLA: o erro vira "não sei", e quem chama deixa o tempo nulo. Deixar
    /// a exceção subir impediria o admin de criar uma parada.
    @Test
    void erroDoServidorViraVazioEmVezDeExcecao() {
        server.expect(requestTo(org.hamcrest.Matchers.containsString("/route/")))
                .andRespond(withServerError());

        assertThat(adapter.legDurationsSeconds(List.of(RODOVIARIA, UNIFOR)))
                .isEmpty();
    }

    @Test
    void respostaSemRotaViraVazio() {
        server.expect(requestTo(org.hamcrest.Matchers.containsString("/route/")))
                .andRespond(withSuccess("""
                        {"code":"NoRoute","routes":[]}
                        """, MediaType.APPLICATION_JSON));

        assertThat(adapter.legDurationsSeconds(List.of(RODOVIARIA, UNIFOR))).isEmpty();
    }

    /// Um ponto só não tem trecho pra medir. Sair pra rede aqui gastaria
    /// requisição de um serviço com limite de uso pra receber erro.
    @Test
    void umPontoSoNemChegaAConsultar() {
        assertThat(adapter.legDurationsSeconds(List.of(RODOVIARIA)))
                .isEqualTo(Optional.empty());
        server.verify();
    }
}
