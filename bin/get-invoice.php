<?php declare(strict_types=1);


function handle(Ctx $ctx, string $invoice_id) {
    $invoice = $ctx->invoice($invoice_id);
    $json = json_encode($invoice, JSON_PRETTY_PRINT);
    header('Content-Type: application/json');
    echo $json;
}

setlocale(LC_MONETARY, 'en_US');
function money($num) : string {
    $num = $num ?: 0;
    return money_format('%n', $num);
}

function method($ob, $name) {
    return Closure::fromCallable([ $ob, $name ]);
}

function fn($name) {
    return Closure::fromCallable($name);
}

function mapField($array, $name, $fns) {

    $value = $array['fields'][$name];
    foreach ($fns as $fn) {
        $value = $fn($value);
    }

    $array['fields'][$name] = $value;
    return $array;
}

function pipeline($object, ...$pairs) {
    foreach ($pairs as $args) {
        $field = array_shift($args);
        $object = mapField($object, $field, $args);
    }
    return $object;
}

class RequestCtx {

    private $base_url;
    private $stream_opts;

    public function __construct(string $auth_key, string $space) {
        $this->base_url = "https://api.airtable.com/v0/{$space}/";
        $this->stream_opts = [
            'http' => [
                'method' => 'GET',
                'header' => "Authorization: Bearer $auth_key"
            ]
        ];
    }

    private function req(string $path) : array {
        $context = stream_context_create($this->stream_opts);
        $url = $this->base_url . $path;
        $content = file_get_contents($url, false, $context);
        return json_decode($content, true);
    }

    public function invoice($id) {
        return $this->req("Invoice/$id");
    }

    public function client($id) {
        return $this->req("Clients/$id");
    }

    public function invoiceItem($id) {
        return $this->req("Invoice%20Item/$id");
    }

}

class Ctx {

    private $req_ctx;

    public function __construct(RequestCtx $req_ctx) {
        $this->req_ctx = $req_ctx;
    }

    public function invoiceItem($id) {
        return pipeline($this->req_ctx->invoiceItem($id),
            [ 'Amount', fn('money') ]
        );
    }

    public function invoiceItems($ids) {
        return array_map(method($this, 'invoiceItem'), $ids);
    }

    public function invoice($id) {
        return pipeline($this->req_ctx->invoice($id),
            [ 'Total Amount', fn('money') ],
            [ 'Client', fn('reset'), method($this->req_ctx, 'client') ],
            [ 'Invoice Item', method($this, 'invoiceItems') ]
        );
    }

}

$ctx = new RequestCtx($_ENV['AIRTABLE_KEY'], $_ENV['AIRTABLE_APP']);
$ctx = new Ctx($ctx);
handle($ctx, $_GET['invoice_id']);
